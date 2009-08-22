package Text::xSV::Slurp;

use warnings;
use strict;

use Carp 'confess';
use Exporter;
use Text::CSV;

use base 'Exporter';

our @EXPORT = qw/ xsv_slurp /;

=head1 NAME

Text::xSV::Slurp - Slurp xSV data into common data shapes.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Text::xSV::Slurp 'xsv_slurp';
    
    xsv_slurp( file => 'foo.csv',
              shape => 'hoh',
              index => 'id',
          
=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 xsv_slurp

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
   my %o = @_;
   
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
      
   my $shape  = defined $o{'shape'} ? lc $o{'shape'} : 'aoh';
   my $shaper = $shape_map{ $shape };
   
   if ( ! $shaper )
      {
      my @all_shapes = keys %shape_map;
      confess "Error: unrecognized shape given ($shape). Must be one of: @all_shapes"
      }
   
   my $src      = $given_srcs[0];
   my $handle   = _get_handle( $src => $o{$src} );
   my %csv_opts = %o;
   
   delete $csv_opts{$_} for qw/ file handle string shape key /;
   
   my $csv  = Text::CSV->new( \%csv_opts );
   my $data = $shaper->( $handle, $csv, \%o );
   
   return $data;
   }
   
sub _as_aoa
   {
   my ( $handle, $csv, $o ) = @_;
   
   my @aoa;
   
   while ( my $line = <$handle> )
      {
      chomp $line;
      
      if ( ! $csv->parse($line) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      push @aoa, [ $csv->fields ];
      
      }
   
   return \@aoa;
   }   
   
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
      
      while ( my $line = <$handle> )
         {
         chomp $line;
         
         if ( ! $csv->parse($line) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         my %line;
         
         @line{ @headers } = $csv->fields;
            
         push @aoh, \%line;
         
         }
         
      }

   return \@aoh;
   }   

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
      
      @hoa{ @headers } = map { [] } @headers;
      
      while ( my $line = <$handle> )
         {
         chomp $line;
         
         if ( ! $csv->parse($line) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         my %line;
         
         @line{ @headers } = $csv->fields;

         for my $k ( @headers )
            {
            push @{ $hoa{$k} }, $line{$k};
            }
            
         }
         
      }

   return \%hoa;
   }   

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
      
      if ( ! $csv->parse( $o->{'key'} ) )
         {
         confess 'Error: ' . $csv->error_diag;
         }
         
      my @key = $csv->fields;

      while ( my $line = <$handle> )
         {
         chomp $line;
         
         if ( ! $csv->parse($line) )
            {
            confess 'Error: ' . $csv->error_diag;
            }
            
         my %line;
         
         @line{ @headers } = $csv->fields;
         
         my $leaf = \%hoh;
         
         for my $k ( @key )
            {
            
            my $v         = $line{$k};
            $leaf->{$v} ||= {};
            $leaf         = $leaf->{$v};
            
            }
            
         delete @line{ @key };
         
         %{ $leaf } = %line;
            
         }
         
     }

   return \%hoh;
   }   

sub _get_handle
   {
   my ( $src_type, $src_value ) = @_;
   
   if ( $src_type eq 'handle' )
      {
      return $src_value;
      }
      
   if ( $src_type eq 'string' )
      {
      open( my $handle, '<', \$src_value ) || confess "Error opening string handle: $!";
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
