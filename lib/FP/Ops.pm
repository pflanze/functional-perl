#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Ops -- function wrappers around Perl ops

=head1 SYNOPSIS

 use FP::Ops 'add';

 our $fibs; $fibs=
   cons 1, cons 1, lazy { stream_zip_with \&add, Keep($fibs), rest $fibs };

=head1 DESCRIPTION

There's no way to take a code reference to Perl operators, hence a
subroutine wrapper is necessary to pass them as arguments. This module
provides them.

Also similarly, `the_method("foo", @args)` returns a function that
does a "foo" method call on its argument, passing @args and then
whatever additional arguments the function receives.

Also, `operator_2("foo")` returns a function that uses "foo" as
operator between 2 arguments. `operator_1("foo")` returns a function
that uses "foo" as operator before its single argument.

=cut


package FP::Ops;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
		 add
		 subt
		 mult
		 div
		 mod
		 expt
		 string_cmp
		 number_cmp
		 the_method
		 operator_2
		 operator_1
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;

sub add {
    my $t=shift;
    $t+= $_ for @_;
    $t
}

sub subt {
    my $t=shift;
    # XXX: should subt($x) == -$x ?
    $t-= $_ for @_;
    $t
}

sub mult {
    my $t=shift;
    $t*= $_ for @_;
    $t
}

sub div {
    my $t=shift;
    # XXX: should div($x) == 1/$x ?
    $t/= $_ for @_;
    $t
}

sub mod {
    my $t=shift;
    # XXX: dito
    $t%= $_ for @_;
    $t
}

sub expt {
    @_==2 or die "need 2 arguments";
    my ($a,$b)=@_;
    $a ** $b
}

sub string_cmp ($ $) {
    $_[0] cmp $_[1]
}

sub number_cmp ($ $) {
    $_[0] <=> $_[1]
}

sub the_method {
    my ($method,@args)=@_;
    sub {
	my $self=shift;
	$self->$method(@args,@_)
	  # any reason to put args before or after _ ? So far I only
	  # have args, no _.
    }
}

sub operator_2 ($) {
    @_==1 or die "need 1 argument";
    my ($code)=@_;
    eval 'sub ($$) { @_==2 or die "need 2 arguments"; $_[0] '.$code.' $_[1] }'
      || die "operator_2: '$code': $@";
}

sub operator_1 ($) {
    @_==1 or die "need 1 argument";
    my ($code)=@_;
    eval 'sub ($) { @_==1 or die "need 1 argument"; '.$code.' $_[0] }'
      || die "operator_1: '$code': $@";
}

TEST { my $lt= operator_2 "lt";
       [map { &$lt (@$_) }
	([2,4], [4,2], [3,3], ["abc","bbc"], ["ab","ab"], ["bbc", "abc"])] }
  [1,'','', 1, '', ''];

TEST { my $neg= operator_1 "-";
       [map { &$neg ($_) }
	(3, -2.5, 0)] }
  [-3, 2.5, 0];


1
