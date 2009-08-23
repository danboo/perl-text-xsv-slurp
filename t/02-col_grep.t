use warnings;
use strict;

use Test::More tests => 2;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'aoa',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      [ ['b'], ['2'], ['5'] ],
      
   opts =>
      {
      shape    => 'aoa',
      col_grep => sub { grep { $_ % 2 } @_ },
      },

   },

   {
   
   id => 'aoh',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      [
      { a => 1, c => 3 },
      { a => 4, c => 6 },
      ],
      
   opts =>
      {
      shape    => 'aoh',
      col_grep => sub { grep { /[ac]/ } @_ },
      },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }
