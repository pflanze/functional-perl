#!/usr/bin/env perl

# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Test::Requires qw(5.020);

use lib "./lib";
use Chj::xperlfunc ":all";

require "./meta/find-perl.pl";

$ENV{RUN_TESTS} = 1;
xexec_safe $^X, "examples/logic";
