use warnings;
use strict;

use Test::More tests => 19;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'no collide',

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
   
   id => 'push collide',

   in => <<EOIN,
a,b,c
1,2,3
1,4,3
EOIN

   exp => 
      {
      1 => { 3 => { b => [2,4] } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'push' },

   },

   {
   
   id => 'unshift collide',

   in => <<EOIN,
a,b,c
1,2,3
1,4,3
EOIN

   exp => 
      {
      1 => { 3 => { b => [4,2] } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'unshift' },

   },

   {
   
   id => 'sum collide',

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
      { shape => 'hoh', key => 'a,c', on_collide => 'sum' },

   },

   {
   
   id => 'hash histogram collide',

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
      { shape => 'hoh', key => 'a,c', on_collide => 'frequency' },

   },

   {
   
   id => 'count collide',

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
      { shape => 'hoh', key => 'a,c', on_collide => 'count' },

   },

   {
   
   id => 'average collide',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,2,3
1,2,3
1,7,3
EOIN

   exp => 
      {
      1 => { 3 => { b => 3 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'average' },

   },

   {
   
   id => 'custom count collide',

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
      { shape => 'hoh', key => 'a,c', on_collide => sub { my %o = @_; return ( $o{old_value} || 0 ) + 1 } },

   },

   {
   
   id => 'frequency collide by key',

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
      1 => { b => { 2 => 5 }, c => 3 },
      },
      
   opts =>
      { shape => 'hoh', key => 'a', on_collide_by_key => { b => 'frequency' } },

   },

   {
   
   id => 'custom count collide by key',

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
      { shape => 'hoh', key => 'a,c', on_collide_by_key => { b => sub { my %o = @_; return ( $o{old_value} || 0 ) + 1 } } },

   },

   {
   
   id => 'count collide by default and sum collide by key',

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
      1 => { b => { 2 => 5 }, c => 15 },
      },
      
   opts =>
      { shape => 'hoh', key => 'a', on_collide => 'frequency', on_collide_by_key => { c => 'sum' } },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }

my $got = eval { xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'die' ) };

my $err = $@;

like( $err, qr/\AError: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'die collide' );

ok( ! $got, 'die collide - return' );

$got = eval { xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'die' ) };

$err = $@;

ok( ! $err, 'die collide - no collision' );

is_deeply($got, { 1 => { b => 1 } }, 'die collide - no collision return');

{

   my $warning;

   local $SIG{__WARN__} = sub { ($warning) = @_ };
   
   my $got = xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'warn' );
   
   like( $warning, qr/\AWarning: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'warn collide' );
   
   is_deeply($got, { 1 => { b => 1 } }, 'warn collide - return');
   
   undef $warning;
   
   $got = xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'warn' );

   ok( ! $warning, 'warn collide - no collision' );
   
   is_deeply($got, { 1 => { b => 1 } }, 'warn collide - no collision return');

}

