package Text::xSV::Eruct;

use warnings;
use strict;

use Carp 'confess', 'cluck';
use Text::CSV;
use IO::String;
use Data::Leaf::Walker;

use base 'Exporter';

our @EXPORT = qw/ xsv_eruct /;

=head1 NAME

Text::xSV::Eruct - Convert common data shapes to xSV format.

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

=head1 SYNOPSIS

C<Text::xSV::Eruct> converts nested data structures of various shapes to xSV
format (typically CSV). It allows both column and row filtering using user
defined functions.

This brief example converts an array of hashes to CSV format, where each array
record corresponds to a line of the file, and each line is represented as a hash
of header-to-value pairs.

    use Text::xSV::Eruct 'xsv_eruct';
    
    my $aoh = [
       { uid => '342', name => 'tim' },
       { uid => '939', name => 'danboo' },
       ];

    xsv_eruct( data => $aoh, file => 'foo.csv' );
    
    ## foo.csv now contains:
    ##
    ##   uid,name
    ##   342,tim
    ##   939,danboo
             
=head1 FUNCTIONS

=head2 C<xsv_eruct()>

C<xsv_eruct()> converts nested data structures, of various shapes, to xSV
(typically CSV) data.

Option summary:

=over

=item * C<data> - data to be convert to xsv

=item * C<file> - file name to be written

=item * C<handle> - file handle to be written to

=item * C<string> - string to be written to (a scalar ref)

=item * C<key> - xSV string or ARRAY used to build the headers of the C<hoh> shape

=item * C<text_csv> - option hash for L<Text::CSV>/L<Text::CSV_XS> constructor

=back

The C<file>, C<handle> and C<string> options are mutually exclusive. Only one
destination parameter may be passed in each call to C<xsv_eruct()>, otherwise a
fatal exception will be raised.

Unlike C<xsv_slurp()>, you do not need to specify the C<shape> parameter, since
it can be determined via inspection of the given C<data>.

The C<text_csv> option can be used to control L<Text::CSV>/L<Text::CSV_XS>
construction. The given HASH reference is passed to the L<Text::CSV>
constructor. If the C<text_csv> option is undefined, the default L<Text::CSV>
constructor is called. For example, to change the separator to a colon, you
could do the following:

   xsv_eruct( file => 'foo.csv',
              data => $hoh,
          text_csv => { sep_char => ':' } );

=cut

my %from_shape_map =
   (
   'aoa' => \&_from_aoa,
   'aoh' => \&_from_aoh,
   'hoa' => \&_from_hoa,
   'hoh' => \&_from_hoh,
   );

sub xsv_eruct
   {
   my @o = @_;
   
   ## guess the destination if there is an odd number of args
   if ( @o % 2 )
      {
      my $dst = shift @o;
      if ( ref $dst eq 'GLOB' )
         {
         @o = ( handle => $dst, @o );
         }
      elsif ( ref $dst eq 'SCALAR' )
         {
         @o = ( string => $dst, @o );
         }
      else
         {
         @o = ( file => $dst, @o );
         }
      }

   my %o = @o;
   
   ## validate the destination type   
   my @all_dsts   = qw/ file handle string /;
   my @given_dsts = grep { defined $o{$_} } @all_dsts;
   
   my $buffer;
   
   if ( ! @given_dsts )
      {
      confess "Error: no destination given, specify one of: @all_dsts.";
      }
   elsif ( @given_dsts > 1 )
      {
      confess "Error: too many destinations given (@given_dsts), specify only one.";
      }
      
   ## guess the data shape
   my $shape  = _guess_shape( $o{data} );
   
   ## create the CSV parser
   my $csv    = Text::CSV->new( $o{text_csv} || () );

   ## isolate the destination
   my $dst    = $given_dsts[0];

   ## convert the destination to a handle
   my $handle = _get_handle( $dst => $o{$dst}, '>' );

   ## perform the write
   $from_shape_map{$shape}->( $handle, $csv, \%o );
   
   if ( $dst eq 'string' )
      {
      ${ $o{string} } = ${ $handle->string_ref };
      }

   if ( $dst ne 'handle' )
      {
      close $handle;
      }
   
   }

## arguments:
## $dst_type  - type of data destination, handle, string or file
## $dst_value - the file name, file handle or xSV string
sub _get_handle
   {
   my ( $dst_type, $dst_value, $mode ) = @_;

   if ( $dst_type eq 'handle' )
      {
      return $dst_value;
      }

   if ( $dst_type eq 'string' )
      {
      if ( ref $dst_value )
         {
         $dst_value = ${ $dst_value };
         }
      my $handle = IO::String->new( $mode eq '<' ? $dst_value : () );
      return $handle;
      }

   if ( $dst_type eq 'file' )
      {
      open( my $handle, $mode, $dst_value ) || confess "Error: could not open '$dst_value': $!";
      return $handle;
      }

   confess "Error: could not determine destination type";
   }

{

my $ref_map =
   {
   'HASH' => 'h',
   'ARRAY' => 'a',
   };

## arguments:
## $data: the data structure to be eructed
sub _guess_shape
   {
   my ( $data ) = @_;
   
   my $shape = $ref_map->{ ref $data } || '';
   
   $shape || die 'Error: could not determine data shape (invalid top)';
   
   my $nested = $shape eq 'a'
              ? $data->[0]
              : ( values %{ $data } )[0];

   $nested || die 'Error: could not determine data shape (no nested data)';
   
   $shape .= 'o' . ( $ref_map->{ ref $nested } || '' );

   length $shape == 3 || die 'Error: could not determine data shape (invalid nested)';

   return $shape;
   }

}

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _from_aoa
   {
   my ( $handle, $csv, $o ) = @_;
   
   for my $row ( @{ $o->{data} } )
      {
      
      $csv->print( $handle, $row );
      
      print $handle "\n";
      
      }
   }

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _from_aoh
   {
   my ( $handle, $csv, $o ) = @_;
   
   my %headers;
   
   for my $row ( @{ $o->{data} } )
      {
      
      for my $h ( keys %{ $row } )
         {
         $headers{$h}++;
         }
      
      }
      
   my @headers = sort
      {
      $headers{$b} <=> $headers{$a} || $a cmp $b
      }
      keys %headers;

   $csv->print( $handle, \@headers );
      
   print $handle "\n";

   for my $row ( @{ $o->{data} } )
      {
      
      my @row = map { defined $row->{$_} ? $row->{$_} : '' } @headers;

      $csv->print( $handle, \@row );

      print $handle "\n";

      }

   }

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _from_hoa
   {
   my ( $handle, $csv, $o ) = @_;
   
   my @headers = sort
      {
      $#{ $o->{data}{$b} } <=> $#{ $o->{data}{$a} } || $a cmp $b
      }
      keys %{ $o->{data} };   
   
   $csv->print( $handle, \@headers );
      
   print $handle "\n";
   
   for my $row_i ( 0 .. $#{ $o->{data}{$headers[0]} } )
      {
      my @row = map { my $r = $o->{data}{$_}[$row_i]; defined $r ? $r : '' } @headers;

      $csv->print( $handle, \@row );

      print $handle "\n";
      }

   }

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _from_hoh
   {
   my ( $handle, $csv, $o ) = @_;
   
   my @key;

   if ( ref $o->{key} )
      {
      @key = @{ $o->{key} };
      }
   else
      {

      if ( ! $csv->parse($o->{key}) )
         {
         confess 'Error: ' . $csv->error_diag;
         }

      @key = $csv->fields;
      }

   my $twig_depth = @key;
   my $walker     = Data::Leaf::Walker->new(
                       $o->{data},
                       max_depth => $twig_depth,
                       min_depth => $twig_depth,
                       );
   
   my $sample_twig = ( $walker->each )[1];
   
   $walker->reset;

   my %headers = %{ $sample_twig };
   
   delete @headers{ @key };
   
   my @headers = sort keys %headers;
   
   $csv->print( $handle, [ @key, @headers ] );
   
   print $handle "\n";

   while ( my ( $twig_path, $twig ) = $walker->each )
      {

      my @values = ( @{ $twig_path }, @{ $twig }{ @headers } );     
            
      $csv->print( $handle, \@values );

      print $handle "\n";

      }

   }
   
=head1 AUTHOR

Dan Boorstein, C<< <dan at boorstein.net> >>

=head1 TODO

=over

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-xsv-slurp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-xSV-Slurp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::xSV::Eruct


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-xSV-Slurp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-xSV-Slurp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-xSV-Slurp>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-xSV-Slurp/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Boorstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::xSV::Slurp
