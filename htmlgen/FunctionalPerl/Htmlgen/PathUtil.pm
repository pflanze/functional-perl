#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
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

This is alpha software! Read the package README.

=cut


package FunctionalPerl::Htmlgen::PathUtil;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(path_add path_diff
              path0
              path_path0_append
            );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;


# move to lib
use File::Spec;
use FP::Path;
use Chj::xperlfunc qw(dirname);
use Chj::TEST ":all";

fun path_add ($base,$rel) {
    FP::Path->new_from_string($base)->add
        (FP::Path->new_from_string($rel), 1)
          ->string
}

TEST{path_add "/foo", "/zoo" } "/zoo";
TEST{path_add "/foo", "../zoo" } "/zoo";
TEST{path_add "/foo", "zoo/loo" } "/foo/zoo/loo";
TEST{path_add "/foo", "zoo//loo/." } "/foo/zoo/loo/";
TEST{path_add ".", "zoo/loo" } "zoo/loo"; # definitely
TEST_EXCEPTION {path_add ".", "../zoo/loo" }
  # "../zoo/loo"; # yes that's something I want, ok?
  "can't take '..' of root directory"; # well, ok?


fun path_diff ($path0from,$path0to) {
    my $from= $path0from=~ m|(.*?)/+$|s ? $1 : dirname $path0from;
    File::Spec->abs2rel($path0to, $from);
}

TEST{path_diff "foo/", "bar.css"} '../bar.css';
TEST{path_diff "foo/bar.html", "bar.css"} '../bar.css';
TEST{path_diff "foo", "bar.css"} 'bar.css';
#TEST{path_diff ".", "bar.css"} 'bar.css';

#/lib



fun path0 ($path) {
    ## ugly way to strip path prefix
    my $path0= $path;
    while ($path0=~ s|^\.\./||){}; die if $path0=~ /\.\./;
    $path0
}


# a path-append that doesn't output leading './'
fun path_path0_append ($dir,$relpath0) {
    my $p= "$dir/$relpath0";
    $p=~ s|^\./||;
    $p
}



1
