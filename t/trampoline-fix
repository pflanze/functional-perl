#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

use lib "./lib";
use Chj::xperlfunc ":all";

require "./testmem.pl";
# bleadperl on 64bit system needs enormeously more memory than v5.14.2
# on 32bit. FIXME for the right combinations (or/and increase
# iteration count to trigger it even with too high limits)
my $m= ($^V->{version}[1] < 15 ? 30 : 100);
warn "m=$m" if $ENV{RUN_TESTS_VERBOSE};
setlimit_mem_MB ($m);

use Test::Requires qw(Method::Signatures);

# Also need Sub::Call::Tail:

if (eval {require Sub::Call::Tail; 1}) {

    $ENV{RUN_TESTS}=1; xexec_safe "intro/more_tailcalls";

} else {
    # hack to run it without Sub::Call::Tail, e.g. on bleadperl where
    # this can't be installed currently.
    xxsystem_safe ("bin/expand-tail",
                   "intro/more_tailcalls",
                   "intro/.expansion-more_tailcalls");

    $ENV{RUN_TESTS}=1; xexec_safe "intro/.expansion-more_tailcalls";
}
