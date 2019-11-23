#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $len= 672;

use Test::More;
use lib "./lib";
use Chj::xperlfunc qw(xprintln);
use Chj::xIO qw(capture_stdout);
use Chj::Backtrace;

# UNIVERSAL::isa does not require a reference
is do { my $v= "IO"; UNIVERSAL::isa($v,"IO") },
  1;

# just to be sure
is capture_stdout { xprintln (" a Foo") },
  " a Foo\n";


# the actual tests

is capture_stdout { xprintln ("IO") },
  "IO\n";

is capture_stdout { xprintln ("IO", "IO") },
  "IOIO\n";



done_testing;
