#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $len= 210;
require "./meta/test.pl";
require "./meta/find-perl.pl";

use Test::Requires qw(Text::CSV);
use Test::More;

is readin ("examples/csv_to_xml examples/csv_to_xml-example.csv|"),
   readin ("< t/csv_to_xml.expected");

done_testing;
