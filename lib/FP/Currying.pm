#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Currying

=head1 SYNOPSIS

    use FP::Currying;
    # see usage below

=head1 FUNCTIONS

=over 4

=item curry(f)->(arg1)->(arg2)

Takes a function (coderef) f that takes 2 arguments, and returns a
function that takes just 1 argument, which when called returns a
function that takes again 1 argument and when called calls f with the
two separately passed arguments.

    use FP::Array 'array';

    is_deeply curry(*array)->(10)->(20),
              [ 10, 20 ];

=item curry_(f, args..)->(args1..)->(args2..)

Same as curry but accepts multiple arguments in each step.

    is_deeply curry_(*array, 1)->(10, 11)->(20, 21, 23),
              [ 1, 10, 11, 20, 21, 23 ];

=item partial(f, args...)->(args1..)

Takes a function f and fewer than the normal arguments to f, and
returns a fn that takes a variable number of additional args. When
called, the returned function calls f with args + additional args.

(Same as curry_ but with only one step.)

    is_deeply partial(*array, "hi", 1)->(3, 9),
              [ "hi", 1, 3, 9 ];

=item uncurry, uncurry_1_1, uncurry_2_1, uncurry_1_2, uncurry_2_2, uncurry_1_1_1

Sometimes it's easier to write code in a curried fashion. Often users
still expect to receive an uncurried ("normal") version of the
function. `uncurry_1_1 $fn` returns a function that expects 2
arguments, passes the first to $fn and then the second to the function
that $fn returns. Other variants behave similarly: the appendix tells
how many arguments each function level expects; the added numbers
determine how many arguments the resulting function expects.

    my $mult = uncurry sub { my ($x) = @_; sub { my ($y) = @_; $x*$y }};
    is &$mult(2,3), 6;
    # 'uncurry' is an alias to 'uncurry_1_1'.

    my $mult3 = uncurry_2_1 sub { my ($x,$y) = @_; sub { my ($z) = @_; $x*$y*$z }};
    is &$mult3(2,3,4), 24;

=back


=head1 TODO

Add tail-call optimization to the last call in the chain. Waiting till
Sub::Call::Tail is fixed, or better, we've got a switchable variant.

=head1 SEE ALSO

There are also various modules for currying (curry, not uncurry) on
CPAN.

`the_method` and `cut_method` in L<FP::Ops>.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Currying;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(
    curry
    curry_
    partial
    uncurry
    uncurry_1_1
    uncurry_2_1
    uncurry_1_2
    uncurry_2_2
    uncurry_1_1_1
);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);


sub curry ($) {
    @_ == 1 or die "wrong number of arguments";
    my ($f) = @_;
    sub {
        @_ == 1 or die "wrong number of arguments";
        my ($a) = @_;
        sub {
            @_ == 1 or die "wrong number of arguments";
            @_ = ($a, @_);
            goto \&$f
        }
    }
}

# relaxed version
sub curry_ {
    my ($f, @p) = @_;
    sub {
        my @a = @_;
        sub {
            @_ = (@p, @a, @_);
            goto \&$f
        }
    }
}

# https://github.com/clojure/clojure/blob/master/src/clj/clojure/core.clj
# "Takes a function f and fewer than the normal arguments to f, and
# returns a fn that takes a variable number of additional args. When
# called, the returned function calls f with args + additional args."
sub partial {
    my ($f, @p) = @_;
    sub {
        @_ = (@p, @_);
        goto \&$f
    }
}

# Macros would be useful here.

sub uncurry_1_1 ($) {
    my ($f) = @_;
    sub {
        @_ == 2 or die "expecting 2 arguments";
        my ($a, $b) = @_;
        $f->($a)->($b)
    }
}

sub uncurry ($);
*uncurry = *uncurry_1_1;

sub uncurry_2_1 ($) {
    my ($f) = @_;
    sub {
        @_ == 3 or die "expecting 3 arguments";
        my ($a, $b, $c) = @_;
        $f->($a, $b)->($c)
    }
}

sub uncurry_1_2 ($) {
    my ($f) = @_;
    sub {
        @_ == 3 or die "expecting 3 arguments";
        my ($a, $b, $c) = @_;
        $f->($a)->($b, $c)
    }
}

sub uncurry_2_2 ($) {
    my ($f) = @_;
    sub {
        @_ == 4 or die "expecting 4 arguments";
        my ($a, $b, $c, $d) = @_;
        $f->($a, $b)->($c, $d)
    }
}

sub uncurry_1_1_1 ($) {
    my ($f) = @_;
    sub {
        @_ == 3 or die "expecting 3 arguments";
        my ($a, $b, $c) = @_;
        $f->($a)->($b)->($c)
    }
}

# ...

1
