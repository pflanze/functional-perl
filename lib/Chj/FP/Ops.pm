#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Ops -- function wrappers around Perl ops

=head1 SYNOPSIS

 use Chj::FP::Ops 'add';

 our $fibs; $fibs=
   cons 1, cons 1, Delay { stream_zip_with \&add, Keep($fibs), rest $fibs };

=head1 DESCRIPTION

There's no way to take a code reference to Perl operators, hence a
subroutine wrapper is necessary to pass them as arguments. This module
provides them.

Also similarly, `the_method("foo")` returns a function that does a
"foo" method call on its argument.

=cut


package Chj::FP::Ops;
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
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';


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


1
