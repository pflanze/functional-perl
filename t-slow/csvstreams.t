#!/usr/bin/env perl

# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Test::Requires qw(5.020 Text::CSV);
use Test::More;

use lib "./lib";
use Chj::xperlfunc ":all";

require "./meta/find-perl.pl";

require "./testmem.pl";
setlimit_mem_MB($^V->{version}[1] < 15 ? 30 : 80)
    ;    # 14 is enough on 32bit Debian, 64bit will need more

SKIP: {
    if (0) {
        warn "todo: fix perl issue or functional-perl bug";
        skip "Perl issue or functional-perl bug?", 3;    # XXX
    }

    is xsystem_safe($^X, qw"examples/gen-csv t/test-a.csv 40000"), 0;

    # 20000 pass on 32bit Debian even with bug

    is xsystem_safe(
        $^X, qw"examples/csv_to_xml_short t/test-a.csv t/test-a.xml"
        ),
        0;

    is xsystem_safe($^X, qw"examples/csv_to_xml t/test-a.csv -o t/test-a.xml"),
        0;
}

done_testing;
