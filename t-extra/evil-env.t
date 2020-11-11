#!/usr/bin/env perl

# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Cwd 'abs_path';
our ($mydir, $myname); BEGIN {
    my $location = (-l $0) ? abs_path ($0) : $0;
    $location =~ /(.*?)([^\/]+?)_?\z/s or die "?";
    ($mydir, $myname) = ($1,$2);
}
#use lib "$mydir/../lib";


$ENV{TEST} = "0";

exec "make", "test"
    or exit 127;

