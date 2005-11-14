use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::TT',
    AUTHOR    => 'Sebastian Riedel (sri@oook.de)',
    PREREQ_PM => {
        Catalyst        => '5.5',
        Template        => 0,
        Template::Timer => 0
    },
    VERSION_FROM => 'lib/Catalyst/View/TT.pm'
);
