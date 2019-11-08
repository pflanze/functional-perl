use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'FunctionalPerl',
    VERSION_FROM      => 'lib/FP/FunctionalPerl.pm',
    PREREQ_PM         => {'Test::Requires'=> 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?
      (ABSTRACT  => 'FP::FunctionalPerl - functional programming on Perl',
       AUTHOR         => 'Christian Jaeger <copying@christianjaeger.ch>') : ()),
);
