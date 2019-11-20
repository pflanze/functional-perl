use 5.014002;
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME              => 'FP::FunctionalPerl',
    VERSION_FROM      => 'lib/FP/FunctionalPerl.pm',
    META_ADD => {
        prereqs=> {
            runtime=> {
                recommends=> {
                    'Term::ReadLine::Gnu'=> 0,
                    'PadWalker'=> 0,
                    'Eval::WithLexicals'=> 0,
                    'Capture::Tiny'=> 0,
                    # d'oh, ExtUtils::MakeMaker *drops* those
                    # silently, so don't bother or figure out how to
                    # make them end up in MYMETA.json
                    # (https://metacpan.org/pod/CPAN::Meta::Spec)
                },
            },
            test=> {
                # etc., but see note above
            },
        },
    },
    PREREQ_PM         => {
        # e.g., Module::Name => 1.1
        "Scalar::Util"=> 0,
    },
    TEST_REQUIRES => {'Test::Requires'=> 0},
    ($] >= 5.005 ?
      (ABSTRACT  => 'FP::FunctionalPerl - functional programming on Perl',
       AUTHOR         => 'Christian Jaeger <copying@christianjaeger.ch>') : ()),
);
