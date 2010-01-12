use warnings;
use strict;

use Test::More tests => 6;

use Text::xSV::Eruct;

eval { xsv_eruct() };

like( $@, qr/\A\QError: no destination given, specify one of: file handle string./, 'empty' );

eval { xsv_eruct( data => [[1]] ) };

like( $@, qr/\A\QError: no destination given, specify one of: file handle string./, 'no destination' );

eval { xsv_eruct( \my $foo, data => [[1]], handle => \*STDERR ) };

like( $@, qr/\A\QError: too many destinations given (handle string), specify only one./, 'double destination' );

eval { xsv_eruct( \my $foo ) };

like( $@, qr/\A\QError: could not determine data shape (invalid top)/, 'invalid top' );

eval { xsv_eruct( \my $foo, data => [] ) };

like( $@, qr/\A\QError: could not determine data shape (no nested data)/, 'no nested' );

eval { xsv_eruct( \my $foo, data => [\*STDERR] ) };

like( $@, qr/\A\QError: could not determine data shape (invalid nested)/, 'invalid nested' );