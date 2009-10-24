use warnings;
use strict;

use Test::More tests => 10;

use Text::xSV::Slurp;

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
   
   id => 'assign agg',

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
      { shape => 'hoh', key => 'a,c', agg => 'assign' },

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
      { shape => 'hoh', key => 'a,c', agg => 'push' },

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
      { shape => 'hoh', key => 'a,c', agg => 'sum' },

   },

   {
   
   id => 'hash histogram agg',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,4,3
1,4,3
1,4,3
EOIN

   exp => 
      {
      1 => { 3 => { b => { 2 => 2, 4 => 3 } } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', agg => 'frequency' },

   },

   {
   
   id => 'custom count agg',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,2,3
1,2,3
1,2,3
EOIN

   exp => 
      {
      1 => { 3 => { b => 5 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', agg => sub { my %o = @_; return ( $o{old_value} || 0 ) + 1 } },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }

eval { xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', agg => 'die' ) };

my $err = $@;

like( $err, qr/\AError: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'die agg' );

eval { xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', agg => 'die' ) };

$err = $@;

ok( ! $err, 'die agg - no collision' );

{

   my $warning;

   local $SIG{__WARN__} = sub { ($warning) = @_ };
   
   xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', agg => 'warn' );
   
   like( $warning, qr/\AError: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'warn agg' );
   
   undef $warning;
   
   xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', agg => 'warn' );

   ok( ! $warning, 'warn agg - no collision' );
   
}
