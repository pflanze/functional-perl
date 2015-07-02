use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'FP',
    VERSION_FROM      => 'lib/FP.pm',
    PREREQ_PM         => {'Test::Requires'=> 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/FP.pm',
       AUTHOR         => 'Christian Jaeger <ch@christianjaeger.ch>') : ()),
);
