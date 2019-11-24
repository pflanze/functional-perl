#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';


# find modules from functional-perl working directory (not installed)
use Cwd 'abs_path';
our ($mydir, $myname); BEGIN {
    my $location= (-l $0) ? abs_path ($0) : $0;
    $location=~ /(.*?)([^\/]+?)_?\z/s or die "?";
    ($mydir, $myname)=($1,$2);
}
use lib "$mydir/../lib";
use lib "$mydir/../meta";

require "./meta/find-perl.pl";

# avoid dependency on Sub::Call::Tail:
use lib "./lib";
use lib "./meta";
use Chj::xperlfunc ":all";
xxsystem_safe $^X, "meta/tail-expand";
use lib "$mydir/../.htmlgen";

use Test::More;
use FunctionalPerl::ModuleList;
use FunctionalPerl::Dependencies 'module_needs';

our $modules= modulenamelist;

for my $module (@$modules) {
  SKIP: {
        if (my @needs= module_needs $module) {
            skip "require $module - don't have @needs", 1;
        }
        require_ok $module;
    }
}

my $res;
if (eval {
    $res= Chj::TEST::run_tests();
    1
    }) {

    is $res->fail, 0, "run_tests";
    # XX wanted to add the ->success results to Test::More's
    # statistics; but, no even halfway decent way to do this?
} else {
    diag $@;
    ok 0;
}

done_testing;


#use Chj::ruse;
#use Chj::Backtrace;
#use FP::Repl;
#repl;
