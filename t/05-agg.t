use warnings;
use strict;

use Test::More tests => 3;

use Text::xSV::Slurp 'xsv_slurp';

my @tests =
   (

   {
   
   id => 'no agg',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
EOIN

   exp => 
      {
      1 => { 3 => { b => 2 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c' },

   },

   {
   
   id => 'array agg',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
EOIN

   exp => 
      {
      1 => { 3 => { b => [2,2] } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', agg => '[]' },

   },

   {
   
   id => 'sum agg',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
EOIN

   exp => 
      {
      1 => { 3 => { b => 4 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', agg => '+' },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }