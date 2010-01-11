use warnings;
use strict;

use Test::More;

use Text::xSV::Eruct;

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

   {
   name => 'hoa - 1x1',
   data => { a => [ 1 ] },
   exp  => "a\n1\n",
   },

   {
   name => 'hoa - 2x1',
   data => { a => [ 1 ], b => [ 2 ] },
   exp  => "a,b\n1,2\n",
   },

   {
   name => 'hoa - 1x2',
   data => { a => [ 1, 2 ] },
   exp  => "a\n1\n2\n",
   },

   {
   name => 'hoa - 2x2',
   data => { a => [ 1,3 ], b => [ 2,4 ] },
   exp  => "a,b\n1,2\n3,4\n",
   },

   {
   name => 'hoa - irregular',
   data => { a => [ 1,3 ], b => [ 2,4 ], c => [ 5..7 ] },
   exp  => "c,a,b\n5,1,2\n6,3,4\n7,,\n",
   },

   {
   name => 'hoh - 1 deep, 1 field',
   data => { a => { h2 => 1 } },
   key  => 'h1',
   exp  => "h1,h2\na,1\n",
   },

   {
   name => 'hoh - 1 deep, 2 field',
   data => { a => { h3 => 3, h2 => 1 } },
   key  => 'h1',
   exp  => "h1,h2,h3\na,1,3\n",
   },

   {
   name => 'hoh - 1 deep, 2 field, remove',
   data => { a => { h3 => 3, h2 => 1, h1 => 'c' } },
   key  => 'h1',
   exp  => "h1,h2,h3\na,1,3\n",
   },

   {
   name => 'hoh - 1 deep, 2 field, remove, 2 rows',
   data => { a => { h3 => 3, h2 => 1, h1 => 'c' }, b => { h3 => 4, h2 => 2, h1 => 'c' } },
   key  => 'h1',
   exp  => "h1,h2,h3\na,1,3\nb,2,4\n",
   },

   {
   name => 'hoh - 3 deep, 1 field',
   data => { a => { b => { c => { h4 => 1, h2 => 2 } } } },
   key  => 'h1,h2,h3',
   exp  => "h1,h2,h3,h4\na,b,c,1\n",
   },

   );
   
plan tests => scalar @tests;   
         
for my $test ( @tests )
   {
   my $xsv;
   xsv_eruct( data => $test->{data},
            string => \$xsv,
            ( $test->{key} ? ( key => $test->{key} ) : () ),
            );
   is( $xsv, $test->{exp},  $test->{name} );
   
   }
         
