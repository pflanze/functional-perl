#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
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

`cut_method` is a variant of the_method which takes the object
as the first argument: `cut_method($obj,"foo",@args)` returns a
function that does a "foo" method call on $obj, passing @args and then
whatever additional arguments the function receives.

Also, `binary_operator("foo")` returns a function that uses "foo" as
operator between 2 arguments. `unary_operator("foo")` returns a function
that uses "foo" as operator before its single argument. CAREFUL: make
sure the given strings are secured, as there is no safety check!

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
		 string_eq
		 string_eq
		 string_ne
		 string_lt
		 string_le
		 string_gt
		 string_ge
		 string_lc
		 string_uc
		 string_lcfirst
		 string_ucfirst
		 number_cmp
		 number_eq
		 number_ne
		 number_lt
		 number_le
		 number_gt
		 number_ge
		 the_method
		 cut_method
		 applying
		 binary_operator
		 unary_operator
		 regex_match
		 regex_substitute
		 regex_xsubstitute
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;
use FP::Show;


sub add {
    my $t= 0;
    $t+= $_ for @_;
    $t
}

sub subt {
    @_==1 ? -$_[0] :
      @_ ? do {
          my $t= shift;
          $t-= $_ for @_;
          $t
      } :
      die "need at least 1 argument"
}

sub mult {
    my $t= 1;
    $t*= $_ for @_;
    $t
}

sub div {
    @_==1 ? (1 / $_[0]) :
      @_ ? do {
          my $t= shift;
          $t/= $_ for @_;
          $t
      } :
      die "need at least 1 argument"
}

sub mod {
    @_==2 or die "need 2 arguments";
    my ($a, $b)=@_;
    $a % $b
}

sub expt {
    @_==2 or die "need 2 arguments";
    my ($a, $b)=@_;
    $a ** $b
}

sub string_cmp ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] cmp $_[1]
}

sub string_eq ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] eq $_[1]
}
sub string_ne ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] ne $_[1]
}
sub string_lt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] lt $_[1]
}
sub string_le ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] le $_[1]
}
sub string_gt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] gt $_[1]
}
sub string_ge ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] ge $_[1]
}

sub string_lc ($) {
    @_==1 or die "need 1 argument";
    lc $_[0]
}
sub string_uc ($) {
    @_==1 or die "need 1 argument";
    uc $_[0]
}
sub string_lcfirst ($) {
    @_==1 or die "need 1 argument";
    lcfirst $_[0]
}
sub string_ucfirst ($) {
    @_==1 or die "need 1 argument";
    ucfirst $_[0]
}

sub number_cmp ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] <=> $_[1]
}

sub number_eq ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] == $_[1]
}
sub number_ne ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] != $_[1]
}
sub number_lt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] < $_[1]
}
sub number_le ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] <= $_[1]
}
sub number_gt ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] > $_[1]
}
sub number_ge ($ $) {
    @_==2 or die "need 2 arguments";
    $_[0] >= $_[1]
}

sub the_method {
    @_ or die "wrong number of arguments";
    my ($method,@args)=@_;
    sub {
	my $self=shift;
	$self->$method(@args,@_)
	  # any reason to put args before or after _ ? So far I only
	  # have args, no _.
    }
}

sub cut_method {
    @_>=2 or die "wrong number of arguments";
    my ($object,$method,@args)=@_;
    sub {
	$object->$method(@args,@_)
    }
}

sub applying {
    my @v=@_;
    sub ($) {
	@_==1 or die "wrong number of arguments";
	my ($f)=@_;
	@_=@v; goto &$f
    }
}

sub binary_operator ($) {
    @_==1 or die "need 1 argument";
    my ($code)=@_;
    eval 'sub ($$) { @_==2 or die "need 2 arguments"; $_[0] '.$code.' $_[1] }'
      || die "binary_operator: ".show($code).": $@";
    # XX security?
}

sub unary_operator ($) {
    @_==1 or die "need 1 argument";
    my ($code)=@_;
    eval 'sub ($) { @_==1 or die "need 1 argument"; '.$code.' $_[0] }'
      || die "unary_operator: ".show($code).": $@";
    # XX security?
}

TEST { my $lt= binary_operator "lt";
       [map { &$lt (@$_) }
	([2,4], [4,2], [3,3], ["abc","bbc"], ["ab","ab"], ["bbc", "abc"])] }
  [1,'','', 1, '', ''];

TEST { my $neg= unary_operator "-";
       [map { &$neg ($_) }
	(3, -2.5, 0)] }
  [-3, 2.5, 0];


sub regex_match ($) {
    @_==1 or die "wrong number of arguments";
    my ($re)= @_;
    sub {
	@_==1 or die "wrong number of arguments";
	my ($str)=@_;
	$str=~ /$re/
    }
}

sub regex_substitute {
    @_==2 or die "wrong number of arguments";
    my ($re,$sub)=@_;
    sub {
	@_==1 or die "wrong number of arguments";
	my ($str)=@_;
	$str=~ s/$re/&$sub()/e;
	$str
    }
}

sub regex_xsubstitute {
    @_==2 or die "wrong number of arguments";
    my ($re,$sub)=@_;
    sub {
	@_==1 or die "wrong number of arguments";
	my ($str)=@_;
	$str=~ s/$re/&$sub()/e
	  or die "no match";
	$str
    }
}


1
