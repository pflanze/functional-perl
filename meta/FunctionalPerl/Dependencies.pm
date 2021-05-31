#
# Copyright (c) 2015-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Dependencies

=head1 SYNOPSIS

    use FunctionalPerl::Dependencies 'module_needs';

    #  if (my @needs = module_needs $module) {
    #      skip "- don't have @needs", 1;
    #  }

=head1 DESCRIPTION


=cut

package FunctionalPerl::Dependencies;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw();
our @EXPORT_OK   = qw(have_dependency module_needs);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

# ------------------------------------------------------------------
# Non-core dependencies of modules to decide whether to skip testing
# them.  XX: keep these updated!

our %dependencies = (

    # Don't specify Sub::Call::Tail (if meta/tail-expand can expand it)!

    # "5.020" for experimental 'signatures'
    'FunctionalPerl::Indexing' => [
        "5.020",
        "File::chdir",
        [
            # The called "meta/perlfiles" script needs:
            "FunctionalPerl::Dependencies::ChjBin" => qw( printfield gls filter
                is-perl skiplines )
        ]
    ],
    'Chj::Packages'             => ["5.020"],
    'FP::SortedPureArray'       => ["5.020", "List::BinarySearch"],
    'FP::RegexMatch'            => ["5.020"],
    'FP::JSON'                  => ['JSON', "5.020"],
    'FP::Abstract::Sequence::t' => ['FP::autobox'],
    'Chj::Serialize'            => ['FP::Repl::Dependencies', 'B::Deparse'],
    'FP::Docstring'             => ['B::Deparse'],
    'FP::BigInt'                => ['Math::BigInt'],
    'FP::autobox'               => ['autobox'],
    'FP::Failure'               => ['Path::Tiny'],
    'FP::Text::CSV'             => ['Text::CSV'],
    'FP::url_'                  => ['URI'],
    'Chj::CPAN::ModulePODUrl'   => ['LWP::UserAgent'],
    'FP::DBI'                   => ['DBI'],
    'FunctionalPerl::Htmlgen::UriUtil'  => ['5.020', 'URI'],
    'FunctionalPerl::Htmlgen::PathUtil' => ['5.020', 'File::Spec',],
    'FunctionalPerl::Htmlgen::PathTranslate' =>
        ['5.020', 'FunctionalPerl::Htmlgen::PathUtil'],
    'FunctionalPerl::Htmlgen::Mediawiki'    => ['5.020', 'Encode', 'URI',],
    'FunctionalPerl::Htmlgen::MarkdownPlus' => [
        '5.020',
        'FunctionalPerl::Htmlgen::Htmlparse',
        'Text::Markdown',
        'FunctionalPerl::Htmlgen::Mediawiki'
    ],
    'FunctionalPerl::Htmlgen::Linking' => [
        '5.020',
        'FunctionalPerl::Htmlgen::PathUtil',
        'Chj::CPAN::ModulePODUrl',
        'FunctionalPerl::Htmlgen::UriUtil',
    ],
    'FunctionalPerl::Htmlgen::Htmlparse' => ['5.020', 'HTML::TreeBuilder',],
    'Chj::HTTP::Daemon'                  => ['HTTP::Request',],
    'FunctionalPerl::Htmlgen::PerlTidy' =>
        ['5.020', 'Perl::Tidy', 'FunctionalPerl::Htmlgen::Htmlparse',],
    (
        map { $_ => ['5.020'] }
            qw(
            FP::AST::Perl
            FunctionalPerl::Htmlgen::Toc
            FunctionalPerl::Htmlgen::PXMLMapper
            FunctionalPerl::Htmlgen::FileUtil
            FunctionalPerl::Htmlgen::default_config
            FunctionalPerl::Htmlgen::Cost
            FunctionalPerl::Htmlgen::Nav
            FunctionalPerl::Htmlgen::Sourcelang
            )
    ),
    (
        map { $_ => ['FP::Repl::Dependencies'] }
            qw(
            FP::Repl::Dependencies
            FP::Repl::Repl
            FP::Repl::StackPlus
            FP::Repl::Trap
            FP::Repl::WithRepl
            FP::Repl
            FP::Trie::t
            )
    ),
);

# ------------------------------------------------------------------

use Chj::singlequote qw(singlequote_many);

sub modulename_or_array_to_code {
    my ($modulename_or_array) = @_;
    if (my $r = ref $modulename_or_array) {
        $r eq "ARRAY" or die "invalid datum in dependenies data structure";
        my ($modulename, @args) = @$modulename_or_array;
        my $quotedargs = singlequote_many @args;
        "use $modulename ($quotedargs)"
    } else {

        # "use $modulename_or_array ()" doesn't work for 5.020!
        "require $modulename_or_array"
    }
}

my %have_dependency;

sub have_dependency {
    my ($modulename_or_array) = @_;
    my $code1 = modulename_or_array_to_code $modulename_or_array;
    exists $have_dependency{$code1} ? $have_dependency{$code1} : do {
        my $code = "package\nFunctionalPerl::Dependenies::TMP {
        $code1;
        1
    }";
        my $res = (eval $code or 0);
        $have_dependency{$code1} = $res;
        $res
    }
}

sub module_needs {
    my ($modulename) = @_;
    if (my $ds = $dependencies{$modulename}) {
        map      { modulename_or_array_to_code $_ }
            grep { not have_dependency $_ }
            sort @$ds
    } else {
        ()
    }
}

1
