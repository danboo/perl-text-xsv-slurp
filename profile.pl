use strict;
use warnings;

use lib './lib';

BEGIN
   {
   open my $csv_fh, '>', 'profile.csv' or die;
   my $r = join ',', 1 .. 10;
   for ( 1 .. 500 )
      {
      print $csv_fh $r, "\n";
      }
   close $csv_fh;
   }

use Text::xSV::Slurp;

my $data1 = xsv_slurp( file => 'profile.csv' );
