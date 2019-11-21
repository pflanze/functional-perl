#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Test::Harness;

# make sure not to carry over a TEST=0 setting, which would make
# Chj::TEST based testing fail
$ENV{TEST}=1;

our @t=
  qw(
        require_and_run_tests
        pod_snippets
        fp-struct
        universal-isa
        repl
        testlazy
        testlazy10
        functional_XML-test
        functional_XML-t-div
        csv_to_xml
        htmlgen
        intro-basics
        trampoline-fix
        examples-fibs
        examples-primes
        examples-logic
        predicates
        dbi
        skip-internal
        skip
        skip-leak
        csvstreams
        perl-weaken-coderef-correctness
        perl-weaken-coderef
        perl-goto-leak
   );

our %ignore_win= map { $_=>1 } (
    # these are using the shell via 'readin', should find a way to
    # rework these without using the shell:
    qw(
    skip
    csv_to_xml
    functional_XML-test
    ),
    'testlazy',  # uses checks for SIGPIPE
    'testlazy10', # uses $ENV{TZ} etc.
    # these are using BSD::Resource, so would need more work to get to
    # run on Windows:
    qw(
    skip-leak
    perl-goto-leak
    perl-weaken-coderef
    ),
    );

my $is_win= $^O=~ /win32/i;

runtests(map {"t/$_"}
         grep {
             if ($is_win and $ignore_win{$_}) {
                 warn "skipping test '$_' on windows";
                 0
             } else {
                 1
             }
         }
         @t);
