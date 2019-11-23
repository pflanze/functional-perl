#!/usr/bin/env perl

# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

require "./meta/test.pl";

use Test::More;

require "./testmem.pl";
setlimit_mem_MB (30);

SKIP: {
    skip "Perl issue", 1 unless $ENV{TEST_PERL};

    is readin("t/perl/goto-leak 100000 1 |"),
      "5000050000\n";
}

done_testing;
