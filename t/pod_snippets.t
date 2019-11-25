#!/usr/bin/env perl

# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.


# Run example snippets in POD sections.

# If there's an issue with those, run `DEBUG=1 t/pod_snippets` and
# look at the saved file!


use strict; use warnings; use warnings FATAL => 'uninitialized';

use Test::Requires qw(Test::Pod::Snippets);
use Test::More;
use lib "./meta";
use FunctionalPerl::TailExpand;
use FunctionalPerl::ModuleList;
use FunctionalPerl::Dependencies 'module_needs';
use Chj::Backtrace;
use Chj::xperlfunc ":all";

require "./meta/find-perl.pl";

my %ignore= map{ $_=> 1}
  qw(
    Chj::Class::Array
    FP::DBI
    FP::Trie
    FP::Untainted
    FP::IOStream
    FP::Interfaces
    FP::Repl::AutoTrap
    Chj::Backtrace
    Chj::BinHexOctDec
    Chj::BuiltinTypePredicates
    Chj::CPAN::ModulePODUrl
    Chj::Class::methodnames
    Chj::HTTP::Daemon
    Chj::IO::Command
    Chj::IO::CommandCommon
    Chj::IO::Dir
    Chj::IO::File
    Chj::IO::Pipe
    Chj::IO::PipelessCommand
    Chj::IO::Tempfile
    Chj::IO::WrappedFile
    Chj::Linux::LmSensors
    Chj::NamespaceClean
    Chj::NamespaceCleanAbove
    Chj::Package::OfPath
    FP::Repl::Repl
    FP::Repl::Dependencies
    FP::Repl::Stack
    FP::Repl::StackPlus
    FP::Repl::corefuncs
    Chj::Serialize
    Chj::TerseDumper
    FP::Repl::Trap
    Chj::Unix::Exitcode
    Chj::Unix::Signal
    Chj::Util::AskYN
    FP::Repl::WithRepl
    Chj::chompspace
    Chj::constructorexporter
    Chj::pp
    FP::Repl
    Chj::ruse
    Chj::time_this
    Chj::xIOUtil
    Chj::xhome
    Chj::xopen
    Chj::xopendir
    Chj::xoutpipe
    Chj::xperlfunc
    Chj::xpipe
    Chj::xtmpfile
   );

my $modules= modulenamelist;
#my $modules= [qw(FP::Equal FP::Ops)];

# plan tests=> scalar @$modules;
#  nope, when running direct, each module contributes its own number of
#  tests, not 1.

sub save {
    my ($module, $code)= @_;
    my $file= "tps-$module.pl";
    unlink $file;
    # XX possibly remove line directives from $code.
    open my $out, ">", $file or die "$file: $!";
    print $out $code or die $!;
    close $out or die $!;

    if ($ENV{DEBUG}) {
        print "=== Running again as expanded file '$file' and with FP::Repl::Trap..\n";
        xxsystem_safe($^X, "-Mlib=./lib", "-MFP::Repl::Trap", $file);
    }
}

sub numfailures {
    my @failures= grep {
        not $_->{ok}
    } @{ Test::Builder->new->{Test_Results} };
    #warn "failures: @failures";
    scalar @failures
}

my $namespacenum= 0;

for my $module (@$modules) {
  SKIP: {
        if ($ignore{$module}) {
            print "=== Ignoring pod snippets in $module.\n";
        } else {
            print "=== Running pod snippets in $module ..\n";

            if (my @needs= module_needs $module) {
                skip "test pod snippets in $module - don't have @needs", 1;
            }

            my $tps_direct = Test::Pod::Snippets->new();
            my $fail_before= numfailures;
            my $code= $tps_direct->generate_test( module => $module );
            $code=~ s/(;\s*)no warnings;/${1};/;
            $code=~ s/(;\s*)no strict;/${1}use strict;/;
            $namespacenum++;
            if (eval "package t_pod_snippets_$namespacenum; $code; \n1") {
                my $fail_after= numfailures;
                if ($fail_after == $fail_before) {
                    # done_testing("snippets in $module") but that's part of $code
                } else {
                    fail("pod snippets in $module");
                    save $module, $code;
                }
            } else {
                warn "Exception: $@\n";
                fail("pod snippets in $module");
                save $module, $code;
            }
        }
    }
}

done_testing();
