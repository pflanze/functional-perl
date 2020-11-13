#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::PathUtil

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::PathUtil;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";
use Sub::Call::Tail;
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(path_add path_diff
    path0
    path_path0_append
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;

# move to lib
use File::Spec;
use FP::Path;
use Chj::xperlfunc qw(dirname);
use Chj::TEST ":all";

sub path_add ($base, $rel) {
    __ '($basestr, $relstr) -> $str '
        . '-- throws exception if $relstr goes above all of $basestr (via FP::Path)';
    FP::Path->new_from_string($base)->add(FP::Path->new_from_string($rel), 1)
        ->string
}

TEST { path_add "/foo", "/zoo" } "/zoo";
TEST { path_add "/foo", "../zoo" } "/zoo";
TEST { path_add "/foo", "zoo/loo" } "/foo/zoo/loo";
TEST { path_add "/foo", "zoo//loo/." } "/foo/zoo/loo/";
TEST { path_add ".",    "zoo/loo" } "zoo/loo";            # definitely
TEST_EXCEPTION { path_add ".", "../zoo/loo" }

# "../zoo/loo"; # yes that's something I want, ok?
"can't take '..' of root directory";                      # well, ok?

sub path_diff ($path0from, $path0to) {
    __ '($path0from, $path0to) -> $patstr '
        . '-- (via File::Spec with Windows hack)';
    my $from = $path0from =~ m|(.*?)/+$|s ? $1 : dirname $path0from;
    my $res  = File::Spec->abs2rel($path0to, $from);

    # XX HACK for Windows (why is this using File::Spec, anyway?):
    $res =~ s{\\}{/}sg;
    $res
}

TEST { path_diff "foo/",         "bar.css" } '../bar.css';
TEST { path_diff "foo/bar.html", "bar.css" } '../bar.css';
TEST { path_diff "foo",          "bar.css" } 'bar.css';

#TEST{path_diff ".", "bar.css"} 'bar.css';

#/lib

sub path0($path) {
    __ 'delete "(../)*" prefix, just a hacky way to strip path prefix';
    my $path0 = $path;
    while ($path0 =~ s|^\.\./||) { }
    die if $path0 =~ /\.\./;
    $path0
}

sub path_path0_append ($dir, $relpath0) {
    __ "a path-append that doesn't result in a leading './'";
    my $p = "$dir/$relpath0";
    $p =~ s|^\./||;
    $p
}

1
