#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

our $len = 759;
require "./meta/readin.pl";
require "./meta/find-perl.pl";
use Test::More;

$ENV{N}  = 10;
$ENV{T}  = 0;
$ENV{TZ} = "MET";
is readin("LANG=C TZ=UTC perl functional_XML/testlazy |"),
    readin("< t/testlazy10.expected");

done_testing;
