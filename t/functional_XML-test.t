#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';
 
use lib "./lib";
use Chj::xperlfunc ":all";
use Test::More;

require "./meta/find-perl.pl";

our $len= 672;

xxsystem_safe ($^X, "functional_XML/test", 10001000);

is xslurp("out.xhtml"), xslurp("t/functional_XML-test.expected");

done_testing;
