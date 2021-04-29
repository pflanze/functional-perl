#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
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
our @EXPORT_OK   = qw(have_module module_needs);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

# ------------------------------------------------------------------
# Non-core dependencies of modules to decide whether to skip testing
# them.  XX: keep these updated!

our %dependencies = (

    # Don't specify Sub::Call::Tail (if meta/tail-expand can expand it)!

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
        '5.020',          'FunctionalPerl::Htmlgen::Htmlparse',
        'Text::Markdown', 'FunctionalPerl::Htmlgen::Mediawiki'
    ],
    'FunctionalPerl::Htmlgen::Linking' => [
        '5.020',                   'FunctionalPerl::Htmlgen::PathUtil',
        'Chj::CPAN::ModulePODUrl', 'FunctionalPerl::Htmlgen::UriUtil',
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

my %have_module;

sub have_module {
    my ($modulename) = @_;
    return $have_module{$modulename} if exists $have_module{$modulename};
    $have_module{$modulename} = do {
        eval "require $modulename; 1" or 0
    }
}

sub module_needs {
    my ($modulename) = @_;
    if (my $ds = $dependencies{$modulename}) {
        grep { not have_module $_ } sort @$ds
    } else {
        ()
    }
}

1
