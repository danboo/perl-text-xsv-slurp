package Text::xSV::Slurp;

use warnings;
use strict;

use Carp 'confess', 'cluck';
use Text::CSV;
use IO::String;

use base 'Exporter';

our @EXPORT = qw/ xsv_slurp /;

=head1 NAME

Text::xSV::Slurp - Convert xSV data to common data shapes.

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

C<Text::xSV::Slurp> converts between xSV data and a variety of nested data
shapes, allowing both column and row filtering using user defined functions.

This brief example creates an array of hashes from a file, where each array
record corresponds to a line of the file, and each line is represented as a hash
of header-to-value pairs.

    use Text::xSV::Slurp 'xsv_slurp';
    
    my $aoh = xsv_slurp( 'foo.csv' );
    
    ## if foo.csv contains:
    ##
    ##   uid,name
    ##   342,tim
    ##   939,danboo
    ##
    ## then $aoh contains:
    ##
    ##   [
    ##     { uid => '342', name => 'tim' },
    ##     { uid => '939', name => 'danboo' },
    ##   ]
             
=head1 FUNCTIONS

=head2 C<xsv_slurp()>

C<xsv_slurp()> converts an xSV data source to one of a variety of nested data
shapes. It allows both column and row filtering using user defined functions.

Option summary:

=over

=item * C<file> - file name to be opened

=item * C<handle> - file handle to be iterated

=item * C<string> - string to be parsed

=item * C<shape> - target data structure (C<aoa>, C<aoh>, C<hoa> or C<hoh>)

=item * C<col_grep> - skip a subset of columns based on user callback

=item * C<row_grep> - skip a subset of rows based on user callback

=item * C<key> - xSV string or ARRAY used to build the keys of the C<hoh> shape

=item * C<text_csv> - option hash for L<Text::CSV> constructor

=back

The C<file>, C<handle> and C<string> options are mutually exclusive. Only one
source parameter may be passed in each call to C<xsv_slurp()>, otherwise a fatal
exception will be raised.

The source can also be provided implicitly, without the associated key, and the
source type will be guessed by examining the first item in the option list. If
the item is a reference type, it is treated as a C<handle> source. If the item
contains a newline or carriage return, it is treated as a C<string> source. If
the item passes none of the prior tests, it is treated as a C<file> source.

   ## implicit C<handle> source
   my $aoa = xsv_slurp( \*STDIN, shape => 'aoa' );

   ## implicit C<string> source
   my $aoh = xsv_slurp( "h1,h2\n" . "d1,d2\n" );

   ## implicit C<file> source
   my $aoh = xsv_slurp( 'foo.csv' );

The C<shape> parameter supports values of C<aoa>, C<aoh>, C<hoa> or C<hoh>. The
default shape is C<aoh>. Each shape affects certain parameters differently (see
below).

The C<text_csv> option can be used to control L<Text::CSV> parsing. The given
HASH reference is passed to the L<Text::CSV> constructor. If the C<text_csv>
option is undefined, the default L<Text::CSV> constructor is called. For
example, to change the separator to a colon, you could do the following:

   my $aoh = xsv_slurp( file => 'foo.csv',
                    text_csv => { sep_char => ':' } );

=head3 C<shape>-specific option details:

=over

   ## examples below assume the following data

   h1,h2,h3
   l,m,n
   p,q,r

=back

=head4 aoa

=over

example data structure:

   [
      [ qw/ h1 h2 h3 / ],
      [ qw/ l  m  n  / ],
      [ qw/ p  q  r  / ],
   ]

shape specifics:

=over

=item * C<col_grep> -  passed an ARRAY reference of indexes, should return a
                       list of indexes to be included

=item * C<row_grep> - passed an ARRAY reference of values, should return true or
                      false whether the row should be included or not

=back

full example:

   ## - convert xSV example to an array of arrays
   ## - include only rows containing values matching /[nr]/
   ## - include only the first and last columns 

   my $aoa = xsv_slurp( string   => $xsv_data,
                        shape    => 'aoa',
                        col_grep => sub { return @( shift() }[0,-1] },
                        row_grep => sub { return grep /[nr]/, @{ $_[0] } },
                      );

   ## $aoa contains:
   ##
   ##   [
   ##      [ 'l',  'n' ],
   ##      [ 'p',  'r' ],
   ##   ]

=back

=head4 aoh

=over

example data structure:

   [
      { h1 => 'l', h2 => 'm', h3 => 'n' },
      { h1 => 'p', h2 => 'q', h3 => 'r' },
   ]

shape specifics:

=over

=item * C<col_grep> - passed an ARRAY reference of column names, should return a
                      list of column names to be included

=item * C<row_grep> - passed a HASH reference of column name / value pairs,
                      should return true or false whether the row should be
                      included or not

=back

full example:

   ## - convert xSV example to an array of hashes
   ## - include only rows containing values matching /n/
   ## - include only the h3 column 

   my $aoh = xsv_slurp( string   => $xsv_data,
                        shape    => 'aoh',
                        col_grep => sub { return 'h3' },
                        row_grep => sub { return grep /n/, values %{ $_[0] } },
                      );

   ## $aoh contains:
   ##
   ##   [
   ##      { h3 => 'n' },
   ##   ]

=back

=head4 hoa

=over

example data structure:

   {
      h1 => [ qw/ l p / ],
      h2 => [ qw/ m q / ],
      h3 => [ qw/ n r / ],
   }

shape specifics:

=over

=item * C<col_grep> - passed an ARRAY reference of column names, should return a
                      list of column names to be included

=item * C<row_grep> - passed a HASH reference of column name / value pairs,
                      should return true or false whether the row should be
                      included or not

=back

full example:

   ## - convert xSV example to a hash of arrays
   ## - include only rows containing values matching /n/
   ## - include only the h3 column 

   my $hoa = xsv_slurp( string   => $xsv_data,
                        shape    => 'hoa',
                        col_grep => sub { return 'h3' },
                        row_grep => sub { return grep /n/, values %{ $_[0] } },
                      );

   ## $hoa contains:
   ##
   ##   {
   ##      h3 => [ qw/ n r / ],
   ##   }

=back

=head4 hoh

=over

example data structure (assuming a C<key> of C<'h2,h3'>):

   {
   m => { n => { h1 => 'l' } },
   q => { r => { h1 => 'p' } },
   }

shape specifics:

=over

=item * C<key> - an xSV string or ARRAY specifying the indexing column names

=item * C<col_grep> - passed an ARRAY reference of column names, should return a
                      list of column names to be included

=item * C<row_grep> - passed a HASH reference of column name / value pairs,
                      should return true or false whether the row should be
                      included or not

=back

full example:

   ## - convert xSV example to a hash of hashes
   ## - index using h1 values
   ## - include only rows containing values matching /n/
   ## - include only the h3 column 

   my $hoh = xsv_slurp( string   => $xsv_data,
                        shape    => 'hoh',
                        key      => 'h1',
                        col_grep => sub { return 'h3' },
                        row_grep => sub { return grep /n/, values %{ $_[0] } },
                      );

   ## $hoh contains:
   ##
   ##   {
   ##      l => { h3 => 'n' },
   ##      p => { h3 => 'r' },
   ##   }

=back

=cut

my %shape_map =
   (
   'aoa' => \&_as_aoa,
   'aoh' => \&_as_aoh,
   'hoa' => \&_as_hoa,
   'hoh' => \&_as_hoh,
   );

sub xsv_slurp
   {
   my @o = @_;

   ## guess the source if there is an odd number of args
   if ( @o % 2 )
      {
      my $src = shift @o;
      if ( ref $src )
         {
         @o = ( handle => $src, @o );
         }
      elsif ( $src =~ /[\r\n]/ )
         {
         @o = ( string => $src, @o );
         }
      else
         {
         @o = ( file => $src, @o );
         }
      }

   ## convert argument list to option hash 
   my %o = @o;

   ## validate the source type   
   my @all_srcs   = qw/ file handle string /;
   my @given_srcs = grep { defined $o{$_} } @all_srcs;
   
   if ( ! @given_srcs )
      {
      confess "Error: no source given, specify one of: @all_srcs.";
      }
   elsif ( @given_srcs > 1 )
      {
      confess "Error: too many sources given (@given_srcs), specify only one.";
      }

   ## validate the shape      
   my $shape  = defined $o{'shape'} ? lc $o{'shape'} : 'aoh';
   my $shaper = $shape_map{ $shape };
   
   if ( ! $shaper )
      {
      my @all_shapes = keys %shape_map;
      confess "Error: unrecognized shape given ($shape). Must be one of: @all_shapes"
      }
   
   ## isolate the source
   my $src      = $given_srcs[0];
   
   ## convert the source to a handle
   my $handle   = _get_handle( $src => $o{$src} );
   
   ## create the CSV parser
   my $csv      = Text::CSV->new( $o{'text_csv'} || () );
   
   ## run the data conversion
   my $data     = $shaper->( $handle, $csv, \%o );
   
   return $data;
   }

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_aoa
   {
   my ( $handle, $csv, $o ) = @_;
   
   my @aoa;

   my @cols;
   my $col_grep;
   
   while ( my $line = <$handle> )
      {
      chomp $line;
      
      if ( ! $csv->parse($line) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      my @line = $csv->fields;

      ## skip unwanted rows
      if ( defined $o->{'row_grep'} )
         {
         next if ! $o->{'row_grep'}->( \@line );
         }
      
      ## remove unwanted cols   
      if ( defined $o->{'col_grep'} )
         {
         if ( ! $col_grep )
            {
            $col_grep++;
            @cols = $o->{'col_grep'}->( 0 .. $#line );
            }
         @line = @line[@cols];
         }

      push @aoa, \@line;
      
      }
   
   return \@aoa;
   }   
   
## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_aoh
   {
   my ( $handle, $csv, $o ) = @_;

   my @aoh;
   
   my $header = <$handle>;

   if ( defined $header )
      {
   
      chomp( $header );
   
      if ( ! $csv->parse($header) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      my @headers = $csv->fields;

      my @grep_headers;
      
      if ( defined $o->{'col_grep'} )
         {
         @grep_headers = $o->{'col_grep'}->( @headers );
         }
      
      while ( my $line = <$handle> )
         {
         chomp $line;
         
         if ( ! $csv->parse($line) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         my %line;
         
         @line{ @headers } = $csv->fields;

         ## skip unwanted rows
         if ( defined $o->{'row_grep'} )
            {
            next if ! $o->{'row_grep'}->( \%line );
            }

         ## remove unwanted cols
         if ( defined $o->{'col_grep'} )
            {
            %line = map { $_ => $line{$_} } @grep_headers;
            }
            
         push @aoh, \%line;
         
         }
         
      }

   return \@aoh;
   }   

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_hoa
   {
   my ( $handle, $csv, $o ) = @_;

   my %hoa;
   
   my $header = <$handle>;

   if ( defined $header )
      {
   
      chomp( $header );

      if ( ! $csv->parse($header) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      my @headers = $csv->fields;
      
      my @grep_headers;
      
      if ( defined $o->{'col_grep'} )
         {
         @grep_headers = $o->{'col_grep'}->( @headers );
         @hoa{ @grep_headers } = map { [] } @grep_headers;
         }
      else
         {
         @hoa{ @headers } = map { [] } @headers;
         }
      
      while ( my $line = <$handle> )
         {
         chomp $line;
         
         if ( ! $csv->parse($line) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         my %line;
         
         @line{ @headers } = $csv->fields;

         ## skip unwanted rows
         if ( defined $o->{'row_grep'} )
            {
            next if ! $o->{'row_grep'}->( \%line );
            }

         ## remove unwanted cols
         if ( defined $o->{'col_grep'} )
            {
            %line = map { $_ => $line{$_} } @grep_headers;
            }

         for my $k ( keys %line )
            {
            push @{ $hoa{$k} }, $line{$k};
            }
            
         }
         
      }

   return \%hoa;
   }   

## predefined methods for handling hoh collisions
my %predefined_aggs =
   (
   
   ## average
   ## weighted-average
   
   ## assign
   'assign' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      return $nval;
      },

   ## die
   'die' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      if ( defined $oval )
         {
         confess "Error: key collision in HoH construction";
         }
      },

   ## warn
   'warn' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      if ( defined $oval )
         {
         cluck "Warning: key collision in HoH construction";
         }
      },

   ## sum
   'sum' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      return ( $oval || 0 ) + ( $nval || 0 );
      },

   ## push to array
   'push' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      my $ref = $oval || [];
      push @{ $ref }, $nval; 
      return $ref;
      },

   ## unshift to array
   'unshift' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      my $ref = $oval || [];
      unshift @{ $ref }, $nval; 
      return $ref;
      },

   ## value histogram
   'frequency' =>  sub
      {
      my ( $key, $nval, $oval, $line, $hoh, $scratch ) = @_;
      my $ref = $oval || {};
      $ref->{$nval} ++;
      return $ref;
      },
   
   );

## arguments:
## $handle - file handle
## $csv    - the Text::CSV parser object
## $o      - the user options passed to xsv_slurp   
sub _as_hoh
   {
   my ( $handle, $csv, $o ) = @_;

   my %hoh;
   
   my $header = <$handle>;

   if ( defined $header )
      {
   
      chomp( $header );

      if ( ! $csv->parse($header) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      my @headers = $csv->fields;
      
      my @grep_headers;
      
      if ( defined $o->{'col_grep'} )
         {
         @grep_headers = $o->{'col_grep'}->( @headers );
         }

      my @key;
      
      if ( ref $o->{'key'} )
         {
         
         @key = @{ $o->{'key'} };
         
         }
      else
         {
      
         if ( ! $csv->parse( $o->{'key'} ) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         @key = $csv->fields;

         }

      ## set the aggregation method for each header. currently this is global,
      ## but will eventually be per header.
      my %agg_actions;

      if ( $o->{'agg'} )
         {

         my $agg = $predefined_aggs{ $o->{'agg'} } || $o->{'agg'};

         for my $header ( @headers )
            {

            $agg_actions{$header} = $agg;
               
            }

         }

      while ( my $line = <$handle> )
         {
         chomp $line;
         
         if ( ! $csv->parse($line) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         my %line;
         
         @line{ @headers } = $csv->fields;
         
         ## skip unwanted rows
         if ( defined $o->{'row_grep'} )
            {
            next if ! $o->{'row_grep'}->( \%line );
            }

         ## step through the nested keys
         my $leaf = \%hoh;
         
         for my $k ( @key )
            {
            
            my $v         = $line{$k};
            $leaf->{$v} ||= {};
            $leaf         = $leaf->{$v};
            
            }
         
         ## remove key headers from the line   
         delete @line{ @key };
         
         ## remove unwanted cols
         if ( defined $o->{'col_grep'} )
            {
            %line = map { $_ => $line{$_} } @grep_headers;
            }

         ## perform the aggregation if applicable            
         for my $key ( keys %line )
            {

            my $new_value = $line{$key};

            my $agg = $agg_actions{$key};

            if ( $agg )
               {
               
               $new_value = $agg->( $key, $new_value, $leaf->{$key}, \%line, \%hoh );

               }

            $leaf->{$key} = $new_value;

            }
            
         }
         
     }

   return \%hoh;
   }   

## arguments:
## $src_type  - type of data source, handle, string or file
## $src_value - the file name, file handle or xSV string
sub _get_handle
   {
   my ( $src_type, $src_value ) = @_;

   if ( $src_type eq 'handle' )
      {
      return $src_value;
      }

   if ( $src_type eq 'string' )
      {
      my $handle = IO::String->new( $src_value );
      return $handle;
      }

   if ( $src_type eq 'file' )
      {
      open( my $handle, '<', $src_value ) || confess "Error opening $src_value: $!";
      return $handle;
      }

   confess "Error: could not determine source type";
   }   

=head1 AUTHOR

Dan Boorstein, C<< <dan at boorstein.net> >>

=head1 TODO

=over

=item * agg specific actions by key

=item * add average, weighted-average and count agg keys and tests

=item * add test for warn agg key

=item * die and warn agg keys should include the value path in the output

=item * document hoh 'agg' predefined keys

=item * document hoh 'agg' custom keys

=item * add a recipes/examples section to cover grep and agg examples

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-xsv-slurp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-xSV-Slurp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::xSV::Slurp


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
