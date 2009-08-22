use warnings;
use strict;

use Test::More tests => 1;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'string, defaults',

   in => <<EOIN,
a,b,c
1,2,3
EOIN

   exp => 
      [{
      a => 1,
      b => 2,
      c => 3,
      }],
      
   opts =>
      {},
   },

   {
   
   id => 'header only, string, defaults',

   in => <<EOIN,
a,b,c
EOIN

   exp => 
      [],
      
   opts =>
      {},

   },

   {
   
   id => 'empty, string, defaults',

   in => '',

   exp => 
      [],
      
   opts =>
      {},

   },

   );

for my $test ( @tests )
   {
   use Data::Dumper;
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }