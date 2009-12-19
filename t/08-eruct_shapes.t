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

   {
   name => 'aoa - irregular',
   data => [ [ 1 ], [ 2 .. 3 ], [ 4 .. 6 ] ],
   exp  => "1\n2,3\n4,5,6\n",
   },

   {
   name => 'aoh - 1x1',
   data => [ { a => 1 } ],
   exp  => "a\n1\n",
   },

   {
   name => 'aoh - 2x1',
   data => [ { a => 1, b => 2 } ],
   exp  => "a,b\n1,2\n",
   },

   {
   name => 'aoh - 1x2',
   data => [ { a => 1 }, { a => 2 } ],
   exp  => "a\n1\n2\n",
   },

   {
   name => 'aoh - 2x2',
   data => [ { a => 1, b => 3 }, { a => 2, b => 4 } ],
   exp  => "a,b\n1,3\n2,4\n",
   },

   {
   name => 'aoh - irregular',
   data => [ { a => 1, b => 3 }, { a => 2, b => 4, c => 5 } ],
   exp  => "a,b,c\n1,3,\n2,4,5\n",
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
         
