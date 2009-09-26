use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::xSV::Slurp',
    license             => 'perl',
    dist_author         => q{Dan Boorstein <dan@boorstein.net>},
    dist_version_from   => 'lib/Text/xSV/Slurp.pm',
    build_requires => {
        'Test::More' => 0,
        'Text::CSV'  => 0,
        'IO::String' => 0,
    },
    add_to_cleanup      => [ 'Text-xSV-Slurp-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
