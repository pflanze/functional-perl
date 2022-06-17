my $MIN_PERL_VERSION;

BEGIN {
# * Succeed:
# 5.18.1 http://matrix.cpantesters.org/?dist=FunctionalPerl%200.72.13;os=linux;perl=5.18.1;reports=1 http://www.cpantesters.org/cpan/report/e57320a4-10db-11ea-8681-47711f24ea8f
#
# * Failed test 'at lib/FP/Abstract/Sequence/t.pm line 133'
# 5.16.3 http://www.cpantesters.org/cpan/report/1342cff4-116b-11ea-8a8b-67481f24ea8f http://www.cpantesters.org/cpan/report/cf807ac8-10e8-11ea-946b-116a1f24ea8f http://www.cpantesters.org/cpan/report/ff1b318e-10d8-11ea-80e7-b93663a9c918 http://www.cpantesters.org/cpan/report/25f6f618-1010-11ea-80e7-b93663a9c918
# 5.14.4 (0.72.11) http://www.cpantesters.org/cpan/report/0619cd96-116b-11ea-8a8b-67481f24ea8f
# 5.14.2
#
# * Failed test at t/repl.t line 137.
# 5.16.3 http://www.cpantesters.org/cpan/report/15220aae-1091-11ea-ac3f-09121f24ea8f

    # Let's try 5.16.4 to see if there are versions below 5.17.0 that
    # work
    $MIN_PERL_VERSION = 5.016004;

    # 5.17.0 is older than 5.16.1!
    eval "use $MIN_PERL_VERSION; 1" || die $@;
}
use ExtUtils::MakeMaker;

my $on_unix_like = $^O =~ /dragonfly|bsd|linux|darwin/i;

WriteMakefile(
    NAME             => 'FunctionalPerl',
    VERSION_FROM     => 'lib/FunctionalPerl.pm',
    MIN_PERL_VERSION => $MIN_PERL_VERSION,
    LICENSE => "perl_5",    # including HTTP::Daemon which has the same
    EXE_FILES => [qw(bin/perlrepl bin/fperl)],
    PREREQ_PM => {
        "Getopt::Long"        => 0,
        "base"                => 0,
        "NEXT"                => 0,
        "Symbol"              => 0,
        "utf8"                => 0,
        "Digest"              => 0,
        "Test::More"          => "0.96",    # for ~proper subtest support
        "Scalar::Util"        => 0,
        "Import::Into"        => 0,
        "Math::BigInt"        => 0,
        "File::Path"          => 0,
        "Safe::Isa"           => 0,
        "PerlIO::utf8_strict" => 0,

        # could be optional (tests should skip if not available):
        "autobox" => 0,
    },
    TEST_REQUIRES => {
        "Test::Requires" => 0,

        # Now required; otherwise would have to make it optional in
        # FP::Show, but then tests looking at show output would
        # fail:
        "Capture::Tiny" => 0,

        # Now required, too, to ensure test outputs match:
        "Sub::Util" => 0,

        # for *some* tests:
        ($on_unix_like ? ("BSD::Resource" => 0,) : ()),
        "DBI"                 => 0,
        "DBD::CSV"            => 0,
        "Text::CSV"           => 0,
        "Test::Pod::Snippets" => 0,
        "URI"                 => 0,

        # for meta/FunctionalPerl/Indexing.pm
        "File::chdir" => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => '2', },
        resources   => {
            repository => {
                type => 'git',
                url  => "https://github.com/pflanze/functional-perl.git",
                web  => "https://github.com/pflanze/functional-perl",
            },
        },
        prereqs => {
            runtime => {
                recommends => {
                    "Term::ReadLine::Gnu" => 0,
                    "PadWalker"           => 0,
                    "B::Deparse"          => 0,
                    "Eval::WithLexicals"  => 0,

                    #"Sub::Call::Tail" => 0, currently broken
                    "Method::Signatures" => 0,

                    #"Function::Parameters" => 0, not used anymore

                    # examples/:
                    "JSON" => 0,

                    # for running htmlgen
                    "Encode"         => 0,
                    "LWP::UserAgent" => 0,
                    "Clone"          => 0,
                    "Text::Markdown" => 0,
                },
            },
            test => {},
        },
        no_index => {
            directory => [

                # "t" and "inc" are added anyway.
                "examples",    # ?
                "meta", "htmlgen", "t-slow", "t-extra",
            ],
        },

    },
    (
        $] >= 5.005
        ? (
            ABSTRACT => 'FunctionalPerl - functional programming in Perl',
            AUTHOR   => 'Christian Jaeger <copying@christianjaeger.ch>'
            )
        : ()
    ),
    SIGN => 1,
);
