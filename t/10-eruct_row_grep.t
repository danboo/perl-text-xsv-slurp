use warnings;
use strict;

use Test::More;

use Text::xSV::Eruct;

use Data::Dumper;

my @tests =
   (

   {
   name     => 'aoa',
   data     => [ [ 1 .. 2 ], [ 3 .. 4 ], [ 5 .. 6 ] ],
   row_grep => sub { $_[0]->[0] != 3 },
   exp      => "1,2\n5,6\n",
   },

   {
   name     => 'aoh',
   data     => [ { a => 1 }, { a => 2 }, { a => 3 }, ],
   row_grep => sub { $_[0]->{a} != 2 },
   exp      => "a\n1\n3\n",
   },

   {
   name     => 'hoa',
   data     => { a => [ 1 .. 3 ], b => [ 4 .. 6 ] },
   row_grep => sub { $_[0]->{a} != 2 },
   exp      => "a,b\n1,4\n3,6\n",
   },

   {
   name     => 'hoh',
   data     => { a => { b => { h3 => 1 }, c => { h3 => 2 } } },
   key      => [ qw/ h1 h2 / ],
   row_grep => sub { $_[0]->{h3} != 2 },
   exp      => "h1,h2,h3\na,b,1\n",
   },

   );
   
plan tests => scalar @tests;   
         
for my $test ( @tests )
   {
   my $xsv;
   xsv_eruct( data => $test->{data},
            string => \$xsv,
          row_grep => $test->{row_grep},
            ( $test->{key} ? ( key => $test->{key} ) : () ),
            );
   is( $xsv, $test->{exp},  $test->{name} );
   
   }
         
