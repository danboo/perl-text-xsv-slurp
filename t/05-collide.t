use warnings;
use strict;

use Test::More tests => 14;

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
   
   id => 'assign collide',

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
      { shape => 'hoh', key => 'a,c', on_collide => 'assign' },

   },

   {
   
   id => 'array collide',

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
      { shape => 'hoh', key => 'a,c', on_collide => 'push' },

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

eval { xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'die' ) };

my $err = $@;

like( $err, qr/\AError: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'die collide' );

eval { xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'die' ) };

$err = $@;

ok( ! $err, 'die collide - no collision' );

{

   my $warning;

   local $SIG{__WARN__} = sub { ($warning) = @_ };
   
   xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'warn' );
   
   like( $warning, qr/\AError: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'warn collide' );
   
   undef $warning;
   
   xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'warn' );

   ok( ! $warning, 'warn collide - no collision' );
   
}

