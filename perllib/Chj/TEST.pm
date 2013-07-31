#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::TEST

=head1 SYNOPSIS

 use Chj::TEST;

 TEST { 1+1 } 2; # success
 TEST { 1+1 } "2"; # fails,
     # because equality is compared on the result of Data::Dumper

 # compute also result lazily:
 TEST { 1+1 } GIVES {3-1}; # success

 use Chj::TEST ':all';
 run_tests;

=head1 DESCRIPTION

=head1 SEE ALSO

 Chj::noTEST

=cut


package Chj::TEST;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TEST GIVES);
@EXPORT_OK=qw(run_tests);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

our $tests_by_package={};
our $num_by_package={};

sub TEST (&$) {
    my ($proc,$res)=@_;
    my ($package, $filename, $line) = caller;
    $$num_by_package{$package}++;
    push @{$$tests_by_package{$package}},
      [$proc,$res, $$num_by_package{$package}, ($package, $filename, $line)]
}

sub GIVES (&) {
    my ($thunk)=@_;
    bless $thunk, "Chj::TEST::GIVES";
}

use Data::Dumper;

sub eval_test ($$) {
    my ($t,$stat)=@_;
    my ($proc,$res, $num, $package, $filename, $line)=@$t;
    print "running test $num..";
    my $got= &$proc;
    if (ref ($res) eq 'Chj::TEST::GIVES') {
	$res= &$res;
    }
    my $gotstr= Dumper $got;
    my $resstr= Dumper $res;

    if ($gotstr eq $resstr) {
      succ:
	print "ok\n";
	$$stat{success}++
    } else {
	# second chance: compare ignoring utf8 flags on strings
	local $Data::Dumper::Useperl = 1;
	$gotstr= Dumper $got;
	$resstr= Dumper $res;
	goto succ if ($gotstr eq $resstr);

	print "FAIL at $filename line $line:\n";
	print "       got: $gotstr";
	print "  expected: $resstr";
	$$stat{fail}++
    }
}

sub run_tests_for_package {
    my ($package,$stat)=@_;
    if (my $tests= $$tests_by_package{$package}) {
	local $|=1;
	print "=== running tests in package '$package'\n";
	for my $test (@$tests) {
	    eval_test $test, $stat
	}
    } else {
	print "=== no tests for package '$package'\n";
    }
}

sub run_tests {
    my (@maybe_packages)=@_;
    my $stat= {success=>0, fail=>0};
    if (@maybe_packages) {
	run_tests_for_package $_,$stat for @maybe_packages;
    } else {
	run_tests_for_package $_,$stat for keys %$tests_by_package;
    }
    print "===\n";
    print "=> $$stat{success} success(es), $$stat{fail} failure(s)\n";
    ()
}


1
