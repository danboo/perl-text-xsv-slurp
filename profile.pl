use strict;
use warnings;

use lib './lib';

BEGIN
   {
   open my $csv_fh, '>', 'profile.csv' or die;
   my $r = join ',', 1 .. 10;
   for ( 1 .. 10000 )
      {
      print $csv_fh $r, "\n";
      }
   }

use Devel::NYTProf;

use Text::xSV::Slurp;

my $hoh = xsv_slurp( 'profile.csv',
                     shape => 'hoh',
                     key => '1,2,3'
                   );
