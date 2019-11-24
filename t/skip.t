#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

require "./meta/readin.pl";
require "./meta/find-perl.pl";
use Test::More;

# test non-seekable input
is readin("echo -n hallo | perl examples/skip 1 1 |"), "all";

sub t {
    my ($bufsiz)=@_;
    is readin ("perl examples/skip --bufsiz $bufsiz  1 0 < t/skip.input|"), "ello World.";
    is readin ("perl examples/skip --bufsiz $bufsiz  0 1 < t/skip.input|"), "Hello World";
    is readin ("perl examples/skip --bufsiz $bufsiz  4 5 < t/skip.input|"), "o W";
    is readin ("perl examples/skip --bufsiz $bufsiz  10 1 < t/skip.input|"), "d";
    is readin ("perl examples/skip --bufsiz $bufsiz  11 1 < t/skip.input|"), "";
    is readin ("perl examples/skip --bufsiz $bufsiz  11 2 < t/skip.input 2>&1 |", sub{$_[0]}),
      "skip: only 1 byte(s) left after skipping 11 byte(s)\n";
    is readin ("perl examples/skip --bufsiz $bufsiz  12 1 < t/skip.input 2>&1 |", sub{$_[0]}),
      "skip: no remainder left after skipping 12 byte(s)\n";
}

t 1024;
t 1;
t 3;

done_testing;
