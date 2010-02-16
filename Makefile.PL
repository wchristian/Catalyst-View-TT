use inc::Module::Install 0.87;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Catalyst/View/TT.pm > README' );
}

perl_version '5.008001';

name 'Catalyst-View-TT';
all_from 'lib/Catalyst/View/TT.pm';

requires 'Catalyst'        => '5.7';
requires 'Template'        => 0;
requires 'Class::Accessor' => 0;
requires 'Template::Timer' => 0;
requires 'Path::Class'     => 0;
requires 'MRO::Compat'     => 0;

test_requires 'Test::More';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-View-TT/';

WriteAll;
