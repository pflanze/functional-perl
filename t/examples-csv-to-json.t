#!/usr/bin/env perl

# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Test::Requires { experimental => '"signatures"' };    # usually "5.020"
use experimental 'signatures';

use lib "./lib";
use Test::Requires qw(JSON Text::CSV);
use Test::More;
use Chj::xperlfunc qw(xxsystem_safe xsystem_safe xslurp);

# XX move to a lib?

sub cmp ($a, $b) {
    xslurp($a) eq xslurp($b)
}

sub stripCR($str) {
    $str =~ s/\r//;
}

sub cmp_stripCR ($a, $b) {
    stripCR(xslurp($a)) eq stripCR(xslurp($b))
}

# /move

sub t ($direct_mode, $result_file, @options) {
    local $ENV{GIT_PAGER} = "";    # disable git calling a pager
    my $inpath      = "t/examples-csv-to-json.data/a.csv";
    my $result_path = "t/examples-csv-to-json.data/$result_file";
    my $outpath     = $direct_mode ? $result_path : "$result_path-out";
    xxsystem_safe $^X, "examples/csv-to-json", $inpath, @options, $outpath;
    if ($direct_mode) {
        0 == xsystem_safe(qw(git diff --exit-code), $result_path)
    } else {

  # 0 == xxsystem_safe(qw(diff --strip-trailing-cr -u), $result_path, $outpath);
  # ^ does not work on Windows, so:
        cmp_stripCR $result_path, $outpath
    }
}

sub tests_in_gitmode ($direct_mode) {
    ok t($direct_mode, "a.json");
    ok t($direct_mode, "a.mint", "--mint");
    ok t($direct_mode, "a_auto-integers.json", "--auto-integers");
    ok t($direct_mode, "a_auto-numbers.json", "--auto-numbers");
}

tests_in_gitmode(-e ".git");

done_testing;
