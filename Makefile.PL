my $MIN_PERL_VERSION;
BEGIN {
    $MIN_PERL_VERSION= 5.014002;
    eval "use $MIN_PERL_VERSION; 1" || die $@;
}
use ExtUtils::MakeMaker;
WriteMakefile (
    NAME              => 'FunctionalPerl',
    VERSION_FROM      => 'lib/FunctionalPerl.pm',
    MIN_PERL_VERSION => $MIN_PERL_VERSION,
    LICENSE=> "perl_5", # including HTTP::Daemon which has the same
    PREREQ_PM         => {
        #  These are from perl-modules in Debian, can they be assumed
        #  to be present? Seems that perl-modules is generated from
        #  core, thus yes:
        # "Getopt::Long"=> 0,
        # "base"=> 0,
        # "NEXT"=> 0,
        # "Symbol"=> 0,
        # "utf8"=> 0,
        # "overload"=> 0,
        # "Digest"=> 0,
        # "warnings"=> 0,
        # "Test::More"=> 0,
        
        #  Thile Debian provides this in package
        #  libscalar-list-utils-perl (newer version), it also is in
        #  core:
        # "Scalar::Util"=> 0,
    },
    TEST_REQUIRES => {
        "Test::Requires"=> 0,
    },
    META_MERGE => {
        'meta-spec'=> {
            version => '2',
        },
        resources=> {
            repository=> {
                type=> 'git',
                url=> "https://github.com/pflanze/functional-perl.git",
                web=> "https://github.com/pflanze/functional-perl",
            },
        },
        prereqs=> {
            runtime=> {
                recommends=> {
                    "Term::ReadLine::Gnu"=> 0,
                    "PadWalker"=> 0,
                    "B::Deparse"=> 0,
                    "Eval::WithLexicals"=> 0,
                    "Capture::Tiny"=> 0,
                    #"Sub::Call::Tail"=> 0, currently broken
                    "Sub::Util"=> 0,
                    "Method::Signatures"=> 0,
                    "Function::Parameters"=> 0,

                        # for some tests:
                    "BSD::Resource"=> 0,
                    "DBI"=> 0,
                    "DBD::CSV"=> 0,
                    "Text::CSV"=> 0,
                    "Test::Pod::Snippets"=> 0,
                    "URI"=> 0,

                        # for running htmlgen
                    "Encode"=> 0,
                    "LWP::UserAgent"=> 0,
                    "Clone"=> 0,
                    "Text::Markdown"=> 0,
                },
            },
            test=> {
            },
        },
        no_index=> {
            directory=> [
                # "t" and "inc" are added anyway.
                "examples", # ?
                "meta",
                "htmlgen",
            ],
        },

    },
    ($] >= 5.005 ?
      (ABSTRACT  => 'FunctionalPerl - functional programming on Perl',
       AUTHOR         => 'Christian Jaeger <copying@christianjaeger.ch>') : ()),
);
