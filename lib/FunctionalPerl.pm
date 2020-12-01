#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl - functional programming in Perl

=head1 SYNOPSIS

    use FunctionalPerl;
    FunctionalPerl->VERSION # or $FunctionalPerl::VERSION

    # The actual modules are in the FP:: namespace hierarchy, like:
    use FP::List;

    # But you can also import sets of modules from here, e.g.:
    use FunctionalPerl qw(:sequences :repl);

=head1 DESCRIPTION

Allows Perl programs to be written with fewer side effects.

See the L<Functional Perl|http://functional-perl.org/> home page.

=head1 EXPORTS

L<FunctionalPerl> also acts as a convenience re-exporter, offering
tags to load sets of modules. (It also has one normal export:
`expand_import_tags`, see below.)

Note that the tags and the sets of modules are very much alpha. If you
want to have a better chance of code not breaking, import the modules
you want directly.

Tags can be expanded via:

=for test

    use FunctionalPerl qw(expand_import_tags);
    my ($modules, $unused_tags, $nontags) = expand_import_tags(qw(:dev :most not_a_tag));
    is $$modules{"FP::Failure"}, 2; # number of times used.
    is_deeply $unused_tags,
              [':all', ':ast', ':csv', ':dbi', ':fix', ':git', ':io', ':paths', ':pxml', ':rare', ':trampolines', ':transparentlazy'];
    is_deeply $nontags, ['not_a_tag'];

=head1 SEE ALSO

This is the list of supported import tags and the modules and other tags that they import:

C<:all> -> C<:dev>, C<:io>, C<:most>, C<:rare>

C<:ast> -> L<FP::AST::Perl>

C<:autobox> -> L<FP::autobox>

C<:chars> -> L<FP::Char>

C<:csv> -> L<FP::Text::CSV>

C<:datastructures> -> C<:chars>, C<:maps>, C<:numbers>, C<:sequences>, C<:sets>, C<:tries>

C<:dbi> -> L<FP::DBI>

C<:debug> -> C<:equal>, C<:show>, L<Chj::Backtrace>, L<Chj::pp>, L<Chj::time_this>

C<:dev> -> C<:debug>, C<:repl>, C<:test>, L<Chj::ruse>

C<:doc> -> L<FP::Docstring>

C<:equal> -> L<FP::Equal>

C<:failures> -> L<FP::Failure>

C<:fix> -> L<FP::fix>

C<:functions> -> C<:equal>, C<:failures>, C<:show>, L<FP::Combinators>, L<FP::Combinators2>, L<FP::Currying>, L<FP::Div>, L<FP::Memoizing>, L<FP::Ops>, L<FP::Optional>, L<FP::Predicates>, L<FP::Untainted>, L<FP::Values>

C<:git> -> L<FP::Git::Repository>

C<:io> -> L<Chj::tempdir>, L<Chj::xIO>, L<Chj::xhome>, L<Chj::xopen>, L<Chj::xopendir>, L<Chj::xoutpipe>, L<Chj::xperlfunc>, L<Chj::xpipe>, L<Chj::xtmpfile>, L<FP::IOStream>

C<:lazy> -> C<:streams>, L<FP::Lazy>, L<FP::Weak>

C<:maps> -> L<FP::Hash>, L<FP::PureHash>

C<:most> -> C<:autobox>, C<:datastructures>, C<:debug>, C<:doc>, C<:equal>, C<:failures>, C<:functions>, C<:lazy>, C<:show>

C<:numbers> -> L<FP::BigInt>

C<:paths> -> L<FP::Path>

C<:pxml> -> L<PXML::Serialize>, L<PXML::Util>, L<PXML::XHTML>

C<:rare> -> C<:csv>, C<:dbi>, C<:fix>, C<:git>, C<:paths>, C<:trampolines>

C<:repl> -> L<FP::Repl>, L<FP::Repl::AutoTrap>

C<:sequences> -> C<:streams>, L<FP::Array>, L<FP::Array_sort>, L<FP::List>, L<FP::MutableArray>, L<FP::PureArray>, L<FP::StrictList>

C<:sets> -> L<FP::HashSet>, L<FP::OrderedCollection>

C<:show> -> L<FP::Show>

C<:streams> -> L<FP::IOStream>, L<FP::Stream>, L<FP::Weak>

C<:test> -> L<Chj::TEST>

C<:trampolines> -> L<FP::Trampoline>

C<:transparentlazy> -> C<:streams>, L<FP::TransparentLazy>, L<FP::Weak>

C<:tries> -> L<FP::Trie>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

#   **NOTE**  there is no need to keep SEE ALSO in sync with the definitions,
#   **NOTE**  running meta/update-pod (at release time) will take care of it.

package FunctionalPerl;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use base "Exporter";

our @EXPORT      = ();
our @EXPORT_OK   = qw(expand_import_tags);
our %EXPORT_TAGS = ();

our $VERSION = "0.72.40";

# Export tag to modules and/or other tags; each module will be
# imported with ":all" by default. Where a module name contains " = ",
# the part after the " = " is the comma-separated list of tag names to
# import.
# NOTE: the documentation in "SEE ALSO" is auto-generated from this,
# you do not need to keep it in sync manually.
our $export_desc = +{
    ":autobox" => [qw(FP::autobox=)],

    ":streams"         => [qw(FP::Stream FP::IOStream FP::Weak)],
    ":lazy"            => [qw(FP::Lazy :streams FP::Weak)],
    ":transparentlazy" => [qw(FP::TransparentLazy :streams FP::Weak)],
    ":failures"        => [qw(FP::Failure)],

    ":doc"   => [qw(FP::Docstring)],
    ":show"  => [qw(FP::Show)],
    ":equal" => [qw(FP::Equal)],
    ":debug" => [qw(:show :equal Chj::Backtrace Chj::time_this Chj::pp)],
    ":test"  => [qw(Chj::TEST)],
    ":repl"  => [qw(FP::Repl FP::Repl::AutoTrap)],
    ":dev"   => [qw(:repl :test :debug Chj::ruse)],

    ":functions" => [
        qw(FP::Combinators FP::Combinators2
            FP::Ops FP::Div
            FP::Predicates
            FP::Optional FP::Values
            FP::Memoizing FP::Currying
            FP::Untainted
            :show :equal :failures)
    ],
    ":git"  => [qw(FP::Git::Repository)],
    ":pxml" => [qw(PXML::Util PXML::XHTML PXML::Serialize)],
    ":ast"  => [qw(FP::AST::Perl)],

    ":numbers"   => [qw(FP::BigInt)],
    ":chars"     => [qw(FP::Char)],
    ":sequences" => [
        qw(FP::List FP::StrictList FP::MutableArray
            FP::Array FP::Array_sort
            FP::PureArray
            :streams)
    ],
    ":maps"           => [qw(FP::Hash FP::PureHash)],
    ":sets"           => [qw(FP::HashSet FP::OrderedCollection)],
    ":tries"          => [qw(FP::Trie)],
    ":datastructures" => [qw(:chars :numbers :sequences :maps :sets :tries)],

    ":io" => [
        qw(Chj::xIO Chj::xopen Chj::xtmpfile= Chj::tempdir
            Chj::xpipe= Chj::xoutpipe= Chj::xopendir= Chj::xperlfunc
            Chj::xhome
            FP::IOStream)
    ],
    ":dbi" => [qw(FP::DBI=)],
    ":csv" => [qw(FP::Text::CSV)],

    ":fix"         => [qw(FP::fix)],
    ":trampolines" => [qw(FP::Trampoline)],
    ":paths"       => [qw(FP::Path)],

    ":most" => [
        qw(:lazy :datastructures :equal :show :functions :failures :debug
            :autobox :doc)
    ],
    ":rare" => [qw(:csv :paths :git :dbi  :trampolines :fix)],
    ":all"  => [qw(:most :rare :io :dev)],
};

sub check_off {
    @_ == 3 or die "bug";
    my ($tag, $seen_tags, $seen_modules) = @_;
    my $vals = $$export_desc{$tag} or do {
        require Carp;
        Carp::croak("unknown tag '$tag'");
    };
    for my $tag_or_module (@$vals) {
        if ($tag_or_module =~ /^:/) {
            $$seen_tags{$tag_or_module}++;
            check_off($tag_or_module, $seen_tags, $seen_modules);
        } else {
            $$seen_modules{$tag_or_module}++;
        }
    }
}

sub expand_import_tags {

    # Arguments: tag names and other things. Returns (which tag names
    # are unused, used modules, the other things).
    my @tags         = grep {/^:/} @_;
    my $seen_tags    = +{ map { $_ => 1 } @tags };
    my $seen_modules = +{};
    for my $tag (@tags) {
        check_off $tag, $seen_tags, $seen_modules;
    }
    require FP::HashSet;
    (
        $seen_modules,
        [
            sort keys
                %{ FP::HashSet::hashset_difference($export_desc, $seen_tags) }
        ],
        [grep { not /^:/ } @_]
    )
}

sub split_moduledesc {
    my ($module_and_perhaps_tags) = @_;
    my ($module, $maybe_tags)
        = $module_and_perhaps_tags =~ m{^([^=]+)(?:=(.*))?}
        or die "no match";
    ($module, $maybe_tags)
}

sub export_desc2pod {
    join(
        "",
        map {
            my $a = $$export_desc{$_};
            "C<$_> -> " . join(
                ", ",
                map {
                    if (/^:/) {
                        "C<$_>"
                    } else {
                        my ($module, $maybe_tags) = split_moduledesc $_;
                        "L<$module>"
                    }
                } sort @$a
                )
                . "\n\n"
        } (sort keys %$export_desc)
    )
}

sub import {
    my $pack   = shift;
    my $caller = caller;

    my ($modules, $_unused_tags, $nontags) = expand_import_tags(@_);

    $pack->export_to_level(1, $caller, @$nontags);

    require Import::Into;

    for my $module_and_perhaps_tags (sort keys %$modules) {
        my ($module, $maybe_tags) = split_moduledesc $module_and_perhaps_tags;
        my @tags = split /,/, $maybe_tags // ":all";
        my $path = $module;
        $path =~ s/::/\//sg;
        $path .= ".pm";

        # Do not die right away in an attempt at making this more
        # usable for users where some of the modules don't work:
        if (
            eval {
                require $path;
                1
            }
            )
        {
            $module->import::into($caller, @tags)
        } else {
            my $e    = $@;
            my $estr = "$e";
            $estr =~ s/\n.*//s unless $ENV{FUNCTIONALPERL_VERBOSE};
            warn "NOTE: can't load $module: $estr";
        }
    }
}

1
