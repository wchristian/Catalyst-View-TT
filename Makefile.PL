use inc::Module::Install;

name 'Catalyst-View-TT';
all_from 'lib/Catalyst/View/TT.pm';

requires Catalyst        => '5.7';
requires Template        => 0;
requires Class::Accessor => 0;
requires Template::Timer => 0;
requires Path::Class     => 0;

auto_install;
WriteAll;