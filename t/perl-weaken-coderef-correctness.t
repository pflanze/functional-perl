#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

use lib "./lib";
use Chj::xperlfunc ":all";

require "./meta/find-perl.pl";

# test t/perl-weaken-coderef without memory pressure, to check code
# correctness aside memory behaviour

$ENV{TEST_PERL}=1;
$ENV{N}=800;
$ENV{RES}=320400;
xexec_safe "perl", "t/perl-weaken-coderef.t";
