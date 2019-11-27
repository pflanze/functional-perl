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

use Test::More;
use lib "./meta";
use FunctionalPerl::TailExpand;
use FunctionalPerl::ModuleList;
use FunctionalPerl::Dependencies 'module_needs';

require "./meta/find-perl.pl";

# switch Chj::TEST to TAP style testing (unless requested 'old'), and
# disable FP::Repl::Trap / FP::Repl::AutoTrap (unless requested
# otherwise by another setting than "1"):
$ENV{RUN_TESTS} ||= 1;

plan tests=> 2;

subtest "require"=> sub {
    my $modules= modulenamelist;

    for my $module (@$modules) {
      SKIP: {
            if (my @needs= module_needs $module) {
                   skip "require $module - don't have @needs", 1;
            }
            require_ok $module;
        }
    }
};

subtest "run_tests"=> sub {
    # already loaded by require_ok above:
    Chj::TEST::run_tests();
};

#use Chj::ruse;
#use Chj::Backtrace;
#use FP::Repl;
#repl;
