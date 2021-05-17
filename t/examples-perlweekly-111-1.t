#!/usr/bin/env perl

# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Test::Requires "5.020";
use experimental 'signatures';

use lib "./lib";
use Test::Requires qw(FP::autobox);
use Test::More;
use Chj::xperlfunc qw(xexec_safe);

$ENV{RUN_TESTS} = 1;
xexec_safe $^X, "examples/perl-weekly-challenges/111-1-search_matrix", "--test";
