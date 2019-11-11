#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::TEST

=head1 SYNOPSIS

 use Chj::TEST;
 # or
 use Chj::TEST use=> 'Method::Signatures', use=> ['Foo::Bar', qw(bar baz)],
     require=> 'CGI';
 # ^ this will use or require the indicated modules, and if RUN_TESTS
 # is set and they fail, will gracefully fail with a SKIP testing message
 # (if RUN_TESTS is not set, it will die as normally).

 TEST { 1+1 } 2; # success
 TEST { 1+1 } "2"; # fails,
     # because equality is compared on the result of Data::Dumper

 # compute also result lazily:
 TEST { 1+1 } GIVES {3-1}; # success

 TEST_STDOUT { print "Hello" } "Hello";
 TEST_EXCEPTION { die "Hello" } "Hello"; # " at .. line .." and
                                         # backtrace are cut off


 use Chj::TEST ':all';
 run_tests;
 # or
 run_tests __PACKAGE__, Another::Package;
 # or
 run_tests_ packages=> __PACKAGE__, numbers=>[2..4];
 #   aliases package, number, no also accepted

 # For conditional running the tests as part of a global test suite:
 perhaps_run_tests "main" or do_something_else;
 # This will run run_tests("main") iff the RUN_TESTS environment
 # variable is true, otherwise run do_something_else.

=head1 DESCRIPTION

If the `TEST` environmental variable is set to false (as opposed to
not set at all), tests are dropped. This saves the memory otherwise
required to hold the test code and results.

=head1 SEE ALSO

 Chj::noTEST

=cut


package Chj::TEST;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TEST TEST_STDOUT TEST_EXCEPTION GIVES perhaps_run_tests);
@EXPORT_OK=qw(run_tests run_tests_ no_tests);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Carp;
use Chj::singlequote;

# remove 'use' and 'require' arguments from import list, run them,
# then delegate to Exporter


sub import {
    my $class=shift;
    my ($package, $filename, $line)= caller;
    my @args;
    for (my $i=0; $i < @_; $i++) {
	my $v= $_[$i];
	if ($v eq "use" or $v eq "require") {
	    my $val= $_[$i+1];
	    defined $val
	      or croak "undef given as 'require' parameter";
	    my ($module,@args)= do {
		if (ref($val) eq "ARRAY") {
		    @$val
		} elsif (length $val) {
		    ($val)
		} else {
		    croak "value given as 'require' parameter must be a string or array";
		}
	    };
	    my $smallcode=
	      ("$v $module "
	       .join(",", map {singlequote $_} @args));
	    $filename=~ /[\r\n]/
	      and die "possible security issue"; # XXX: how to do it fully right?
	    my $code= "#line $line $filename\npackage $package; $smallcode; 1";
	    if (eval $code) {
		# ok
	    } else {
		if ($ENV{RUN_TESTS}) {
		    #carp "RUN_TESTS is set and we failed to $smallcode";
		    require Test::More;
		    Test::More::plan (skip_all=> "failed to $smallcode");
		    exit 1; # necessary?
		} else {
		    die $@
		}
	    }
	    $i++;
	} else {
	    push @args, $v
	}
    }
    my $sub= $class->can("SUPER::import")
      or die "$class does not have an 'import' procedure";
    @_=($class, @args); goto &$sub;
}



use Chj::xIO 'capture_stdout_';

our $tests_by_package={};
our $num_by_package={};

our $dropped_tests=0;

sub no_tests () {
    exists $ENV{TEST} and !$ENV{TEST}
}

sub _TEST {
    my ($proc,$res)=@_;
    if (no_tests) {
	$dropped_tests++;
    } else {
	my ($package, $filename, $line) = caller(1);
	$$num_by_package{$package}++;
	push @{$$tests_by_package{$package}},
	  [$proc,$res, $$num_by_package{$package}, ($package, $filename, $line)];
    }
}

sub TEST (&$) {
    _TEST(@_)
}

sub TEST_STDOUT (&$) {
    my ($proc,$res)=@_;
    _TEST(sub{capture_stdout_($proc)}, $res);
}

sub TEST_EXCEPTION (&$) {
    my ($proc,$res)=@_;
    _TEST(sub{
	      if (eval {
		  &$proc();
		  1
	      }) {
		  undef
	      } else {
		  my $msg= "$@";
		  $msg=~ s| at .*? line \d*.*||s;
		  $msg
	      }
	  },
	  $res);
}

sub GIVES (&) {
    my ($thunk)=@_;
    bless $thunk, "Chj::TEST::GIVES";
}

use FP::DumperEqual;
use FP::Show;

sub eval_test ($$) {
    my ($t,$stat)=@_;
    my ($proc,$res, $num, $package, $filename, $line)=@$t;
    print "running test $num..";
    my $got= &$proc;
    if (ref ($res) eq 'Chj::TEST::GIVES') {
	$res= &$res;
    }

    if (dumperequal($got, $res)
        or dumperequal_utf8($got, $res)) {
	print "ok\n";
	$$stat{success}++
    } else {
	my $gotstr= show $got;
	my $resstr= show $res;

	print "FAIL at $filename line $line:\n";
	print "       got: $gotstr\n";
	print "  expected: $resstr\n";
	$$stat{fail}++
    }
}

sub run_tests_for_package {
    my ($package,$stat,$maybe_testnumbers)=@_;
    if (my $tests= $$tests_by_package{$package}) {
	local $|=1;
	if (defined $maybe_testnumbers) {
	    print "=== running selected tests in package '$package'\n";
	    for my $number (@$maybe_testnumbers) {
		if ($number=~ /^\d+\z/ and $number > 0
		    and (my $test= $$tests[$number-1])) {
		    eval_test $test, $stat
		} else {
		    print "ignoring invalid test number '$number'\n";
		}
	    }
	} else {
	    print "=== running tests in package '$package'\n";
	    for my $test (@$tests) {
		eval_test $test, $stat
	    }
	}
    } else {
	print "=== no tests for package '$package'\n";
    }
}

sub unify_values {
    my $maybe_values;
    for (@_) {
	if (ref $_) {
	    push @$maybe_values, @$_
	} elsif (defined $_) {
	    push @$maybe_values, $_
	}
    }
    $maybe_values
}

sub run_tests_ {
    @_ % 2 and die "need even number of arguments";
    my $args= +{@_};
    my $maybe_packages=
      unify_values delete $$args{packages}, delete $$args{package};
    my $maybe_testnumbers=
      unify_values delete $$args{numbers}, delete $$args{number},
	delete $$args{no};
    for (keys %$args) { warn "run_tests_: unknown argument '$_'" }

    my $stat= {success=>0, fail=>0};
    if (defined $maybe_packages and @$maybe_packages) {
	run_tests_for_package $_,$stat,$maybe_testnumbers
	  for @$maybe_packages;
    } else {
	run_tests_for_package $_,$stat,$maybe_testnumbers
	  for keys %$tests_by_package;
    }
    print "===\n";
    print "=> $$stat{success} success(es), $$stat{fail} failure(s)\n";
    $$stat{fail}
}

sub run_tests {
    run_tests_ packages=> [@_];
}

# run tests for test suite:

sub perhaps_run_tests {
    if ($ENV{RUN_TESTS}) {
	# run TEST forms (called as part of test suite)

	die "Tests were dropped due to the TEST environmental "
	  ."variable being set to false"
	    if $dropped_tests;

	require Test::More;
	import Test::More;
	is( eval { run_tests(@_) } // do { diag ($@); undef},
	    0,
	    "run_tests" );
	done_testing();

	1  # so that one can write  `perhaps_run_tests or something_else;`
    } else {
	()
    }
}



1
