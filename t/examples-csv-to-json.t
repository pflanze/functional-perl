#!/usr/bin/env perl

# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';

use lib "./lib";
use Test::Requires qw();
use Test::More;
use Chj::xperlfunc qw(xxsystem xsystem);

sub t ($direct_mode, $result_file, @options) {
    local $ENV{GIT_PAGER} = "";    # disable git calling a pager
    my $inpath      = "t/examples-csv-to-json.data/a.csv";
    my $result_path = "t/examples-csv-to-json.data/$result_file";
    my $outpath     = $direct_mode ? $result_path : "$result_path-out";
    xxsystem "examples/csv-to-json", $inpath, @options, $outpath;
    my @cmd
        = $direct_mode
        ? (qw(git diff --exit-code), $result_path)
        : (qw(diff -u), $result_path, $outpath);
    0 == xsystem @cmd
}

sub tests_in_gitmode ($direct_mode) {
    ok t($direct_mode, "a.json");
    ok t($direct_mode, "a.mint", "--mint");
    ok t($direct_mode, "a_auto-integers.json", "--auto-integers");
    ok t($direct_mode, "a_auto-numbers.json", "--auto-numbers");
}

tests_in_gitmode(-e ".git");

done_testing;
