use warnings;
use strict;

use Test::More;

use Text::xSV::Slurp;

my @tests =
   (

   {
   name => 'aoa - 1x1',
   data => [ [ 1 ] ],
   exp  => "1\n",
   },
   
   {
   name => 'aoa - 2x1',
   data => [ [ 1 .. 2 ] ],
   exp  => "1,2\n",
   },

   {
   name => 'aoa - 1x2',
   data => [ [ 1 ], [ 2 ] ],
   exp  => "1\n2\n",
   },

   {
   name => 'aoa - 2x2',
   data => [ [ 1 .. 2 ], [ 3 .. 4 ] ],
   exp  => "1,2\n3,4\n",
   },

   );
   
plan tests => scalar @tests;   
         
for my $test ( @tests )
   {
   my $xsv;
   xsv_eruct( data => $test->{data},
            string => \$xsv, );
   is( $xsv, $test->{exp},  $test->{name} );
   
   }
         
