#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

require "./meta/readin.pl";

require "./meta/find-perl.pl";

use Test::More;

require "./testmem.pl";
setlimit_mem_MB ($^V->{version}[1] < 15 ? 30 : 80);

is readin("perl t/perl/weaken-coderef 2 50000 |"),
  "3\n";

my $n= $ENV{N} // 80000;
my $res= ($ENV{RES} // 3200040000)."\n";

is readin("perl t/perl/weaken-coderef $n 1 |"),
  $res;

SKIP: {
    skip "Perl issue", 3 unless $ENV{TEST_PERL};
    # XXX is this really a perl issue?

    is readin("perl t/perl/weaken-coderef-alternative-fix Y $n 1 |"),
      $res;

    is readin("perl t/perl/weaken-coderef-alternative-fix rec $n 1 |"),
      $res;

    is readin("perl t/perl/weaken-coderef-alternative-fix haskell_uncurried $n 1 |"),
      $res;

    is readin("perl t/perl/weaken-coderef-alternative-fix '' $n 1 |"),
      $res;

}

done_testing;
