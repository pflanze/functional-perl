#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl - functional programming on Perl

=head1 SYNOPSIS

    use FunctionalPerl;
    FunctionalPerl->VERSION # or $FunctionalPerl::VERSION

    # But all the actual modules are under FP::*, like:
    use FP::List;
    # etc.

    # But you can also import sets of modules from here, e.g.:
    use FunctionalPerl qw(:sequences :repl);

=head1 DESCRIPTION

Allow Perl programs to be written with fewer side effects.

See the L<Functional Perl|http://functional-perl.org/> home page.

=head1 EXPORTS

L<FunctionalPerl> also acts as a convenience re-exporter, offering
tags to load sets of modules.

Note that the tags and the sets of modules are very much alpha. If you
want to have a better chance of code not breaking, import the modules
you want directly.

Tags can be expanded via:

=for test

    my ($modules, $unused_tags)= FunctionalPerl::expand(qw(:dev :most));
    is $$modules{"FP::Failure"}, 2; # number of times used.
    use FP::Equal 'is_equal';
    is_equal $unused_tags,
             [':all', ':csv', ':dbi', ':fix', ':git', ':io', ':path', ':pxml', ':rare', ':trampoline', ':transparentlazy'];

=head1 SEE ALSO

This is the list of supported import tags and the modules that they import:

C<:all>: C<:dev>, C<:io>, C<:most>, C<:rare>

C<:autobox>: L<FP::autobox>

C<:chars>: L<FP::Char>

C<:csv>: L<FP::Text::CSV>

C<:datastructures>: C<:chars>, C<:maps>, C<:numbers>, C<:sequences>, C<:sets>, C<:tries>

C<:dbi>: L<FP::DBI>

C<:debug>: C<:equal>, C<:show>, L<Chj::Backtrace>, L<Chj::pp>, L<Chj::time_this>

C<:dev>: C<:debug>, C<:repl>, C<:test>, L<Chj::ruse>

C<:equal>: L<FP::Equal>

C<:failure>: L<FP::Failure>

C<:fix>: L<FP::fix>

C<:functions>: C<:equal>, C<:failure>, C<:show>, L<FP::Combinators>, L<FP::Div>, L<FP::Memoizing>, L<FP::Ops>, L<FP::Optional>, L<FP::Untainted>, L<FP::Values>, L<FP::uncurry>

C<:git>: L<FP::Git::Repository>

C<:io>: L<Chj::tempdir>, L<Chj::xIO>, L<Chj::xhome>, L<Chj::xopen>, L<Chj::xopendir>, L<Chj::xoutpipe>, L<Chj::xperlfunc>, L<Chj::xpipe>, L<Chj::xtmpfile>, L<FP::IOStream>

C<:lazy>: C<:stream>, L<FP::Lazy>, L<FP::Weak>

C<:maps>: L<FP::Hash>

C<:most>: C<:autobox>, C<:datastructures>, C<:debug>, C<:equal>, C<:failure>, C<:functions>, C<:lazy>, C<:show>

C<:numbers>: L<FP::BigInt>

C<:path>: L<FP::Path>

C<:pxml>: L<PXML::Serialize>, L<PXML::Util>, L<PXML::XHTML>

C<:rare>: C<:csv>, C<:dbi>, C<:fix>, C<:git>, C<:path>, C<:trampoline>

C<:repl>: L<FP::Repl>, L<FP::Repl::AutoTrap>

C<:sequences>: C<:stream>, L<FP::Array>, L<FP::Array_sort>, L<FP::List>, L<FP::MutableArray>, L<FP::PureArray>, L<FP::StrictList>

C<:sets>: L<FP::HashSet>, L<FP::OrderedCollection>

C<:show>: L<FP::Show>

C<:stream>: L<FP::IOStream>, L<FP::Stream>, L<FP::Weak>

C<:test>: L<Chj::TEST>

C<:trampoline>: L<FP::Trampoline>

C<:transparentlazy>: C<:stream>, L<FP::TransparentLazy>, L<FP::Weak>

C<:tries>: L<FP::Trie>


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FunctionalPerl;
@ISA="Exporter"; require Exporter;
@EXPORT=();
@EXPORT_OK=();
%EXPORT_TAGS=();

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $VERSION= "0.72.13";


# Export tag to modules and/or other tags; each module will be
# imported with ":all" by default. Where a module name contains "=",
# the part after the "=" is the comma-separated list of tag names to
# import.
our $export_desc=
  +{
    ":autobox"=> [qw(FP::autobox=)],

    ":stream"=> [qw(FP::Stream FP::IOStream FP::Weak)],
    ":lazy"=> [qw(FP::Lazy :stream FP::Weak)],
    ":transparentlazy"=> [qw(FP::TransparentLazy :stream FP::Weak)],
    ":failure"=> [qw(FP::Failure)],

    ":show"=> [qw(FP::Show)],
    ":equal"=> [qw(FP::Equal)],
    ":debug"=> [qw(:show :equal Chj::Backtrace Chj::time_this Chj::pp)],
    ":test"=> [qw(Chj::TEST)],
    ":repl"=> [qw(FP::Repl FP::Repl::AutoTrap)],
    ":dev"=> [qw(:repl :test :debug Chj::ruse)],

    ":functions"=> [qw(FP::Combinators FP::Ops FP::Div
                       FP::Optional FP::Values
                       FP::Memoizing FP::uncurry
                       FP::Untainted
                       :show :equal :failure)],
    ":git"=> [qw(FP::Git::Repository)],
    ":pxml"=> [qw(PXML::Util PXML::XHTML PXML::Serialize)],

    ":numbers"=> [qw(FP::BigInt)],
    ":chars"=> [qw(FP::Char)],
    ":sequences"=> [qw(FP::List FP::StrictList FP::MutableArray
                       FP::Array FP::Array_sort
                       FP::PureArray
                       :stream)],
    ":maps"=> [qw(FP::Hash)],
    ":sets"=> [qw(FP::HashSet FP::OrderedCollection)],
    ":tries"=> [qw(FP::Trie)],
    ":datastructures"=> [qw(:chars :numbers :sequences :maps :sets :tries)],

    ":io"=> [qw(Chj::xIO Chj::xopen Chj::xtmpfile= Chj::tempdir
                Chj::xpipe= Chj::xoutpipe= Chj::xopendir= Chj::xperlfunc
                Chj::xhome
                FP::IOStream)],
    ":dbi"=> [qw(FP::DBI=)],
    ":csv"=> [qw(FP::Text::CSV)],

    ":fix"=> [qw(FP::fix)],
    ":trampoline"=> [qw(FP::Trampoline)],
    ":path"=> [qw(FP::Path)],

    ":most"=> [qw(:lazy :datastructures :equal :show :functions :failure :debug
                  :autobox)],
    ":rare"=> [qw(:csv :path :git :dbi  :trampoline :fix)],
    ":all"=> [qw(:most :rare :io :dev)],
   };


sub check_off {
    @_==3 or die "bug";
    my ($tag, $seen_tags, $seen_modules)=@_;
    my $vals= $$export_desc{$tag}
      or do {
          require Carp;
          Carp::croak ("unknown tag '$tag'");
      };
    for my $tag_or_module (@$vals) {
        if ($tag_or_module=~ /^:/) {
            $$seen_tags{$tag_or_module}++;
            check_off( $tag_or_module, $seen_tags, $seen_modules );
        } else {
            $$seen_modules{$tag_or_module}++;
        }
    }
}

sub expand {
    # arguments: tag names; returns which tag names are unused, and used modules
    my $seen_tags= +{map {$_=> 1} @_};
    my $seen_modules= +{};
    for my $tag (@_) {
        check_off $tag, $seen_tags, $seen_modules;
    }
    require FP::HashSet;
    ($seen_modules,
     [sort keys %{FP::HashSet::hashset_difference($export_desc, $seen_tags)}])
}

sub split_moduledesc {
    my ($module_and_perhaps_tags)= @_;
    my ($module, $maybe_tags)=
        $module_and_perhaps_tags=~ m{^([^=]+)(?:=(.*))?} or die "no match";
    ($module, $maybe_tags)
}

sub export_desc2pod {
    print
    join("",
         map {
             my $a= $$export_desc{$_};
             "C<$_>: ".
                 join(", ",
                      map {
                          if (/^:/) {
                              "C<$_>"
                          } else {
                              my ($module, $maybe_tags)= split_moduledesc $_;
                              "L<$module>"
                          }
                      } sort @$a)."\n\n"
         } (sort keys %$export_desc))
}

sub import {
    my $pack= shift;
    my $caller= caller;

    my ($modules, $_unused_tags)= expand (@_);

    require Import::Into;

    for my $module_and_perhaps_tags (sort keys %$modules) {
        my ($module, $maybe_tags)= split_moduledesc $module_and_perhaps_tags;
        my @tags= split /,/, $maybe_tags // ":all";
        my $path= $module;
        $path=~ s/::/\//sg;
        $path.= ".pm";
        # Do not die right away in an attempt at making this more
        # usable for users where some of the modules don't work:
        if (eval {
            require $path;
            1
        }) {
            $module->import::into($caller, @tags)
        } else {
            my $e= $@;
            my $estr= "$e";
            $estr=~ s/\n.*//s
                unless $ENV{FUNCTIONALPERL_VERBOSE};
            warn "NOTE: can't load $module: $estr";
        }
    }
}


1
