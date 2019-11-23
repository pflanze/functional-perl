#!/usr/bin/env perl

# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

require "./meta/test.pl";

use Test::More;

require "./testmem.pl";
setlimit_mem_MB (50);

is readin("head -c 200000000 /dev/zero | examples/skip --leaktest 10000000 1 | wc -c |"),
  "189999999\n";

done_testing;
