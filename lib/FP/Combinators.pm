#
# Copyright (c) 2014-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Combinators - function combinators

=head1 SYNOPSIS

    use FP::Ops 'div';
    use FP::Combinators 'flip';

    is div(2,3), 2/3;
    is flip(\&div)->(2,3), 3/2;

=head1 DESCRIPTION

=over 4

I<A combinator is a higher-order function that uses only function
application and earlier defined combinators to define a result from
its arguments.>

L<Combinator (wikipedia.org)|https://en.wikipedia.org/wiki/Combinator>

=back

=head1 SEE ALSO

L<FP::Optional>, L<FP::Combinators2>, L<FP::Predicates>, L<FP::Ops>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Combinators;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(compose compose_scalar maybe_compose compose_1side
    flip flip2of3 rot3right rot3left);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;
use FP::Carp;

sub compose {
    my (@fn) = reverse @_;
    sub {
        my (@v) = @_;
        for my $fn (@fn) {
            @v = &$fn(@v);
        }
        wantarray ? @v : $v[-1]    ## no critic
    }
}

# same as compose, but request scalar context between the calls:

sub compose_scalar {
    my (@fn) = reverse @_;
    my $f0   = pop @fn;
    my $fx   = shift @fn;
    sub {
        my $v = &$fx;
        for my $fn (@fn) {
            $v = &$fn($v);
        }
        @_ = ($v);
        goto &$f0
    }
}

TEST {
    compose(sub { $_[0] + 1 }, sub { $_[0] + $_[1] })->(2, 3)
}
6;
TEST {
    compose_scalar(sub { $_[0] + 1 }, sub { $_[0] + $_[1] })->(2, 3)
}
6;

TEST {
    compose(sub { $_[0] / ($_[1] // 5) }, sub {@_}, sub { $_[1], $_[0] })
        ->(2, 3)
}
1.5;
TEST {
    compose_scalar(sub { $_[0] / ($_[1] // 5) }, sub {@_}, sub { $_[1], $_[0] })
        ->(2, 3)
}
1 / 5;

# a compose that short-cuts when there is no defined intermediate
# result:

sub maybe_compose {
    my (@fn) = reverse @_;
    sub {
        my (@v) = @_;
        for (@fn) {

            # return undef, not (), for 'maybe_'; the latter would ask
            # for convention 'perhaps_', ok?
            return undef unless @v > 1 or defined $v[0];
            @v = &$_(@v);
        }
        wantarray ? @v : $v[-1]    ## no critic
    }
}

TEST {
    maybe_compose(sub { die "foo @_" }, sub {undef}, sub {@_})->(2, 3)
}
undef;
TEST {
    maybe_compose(sub { die "foo @_" }, sub {undef})->(2, 3)
}
undef;
TEST {
    maybe_compose(sub { [@_] }, sub {@_})->(2, 3)
}
[2, 3];

# a compose with 1 "side argument" (passed to subsequent invocations unmodified)
sub compose_1side {
    @_ == 2 or fp_croak_arity 2;
    my ($f, $g) = @_;
    sub {
        my ($a, $b) = @_;

        #XX TCO?
        &$f(scalar &$g($a, $b), $b)
    }
}

use Carp;

# XX should flip work like the curried versions (e.g. in Haskell),
# i.e. not care about remaining arguments and simply flip the first
# two? That would save the need for flip2of3 etc., but it would also
# be less helpful for error-checking.

sub flip {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        @_ == 2 or fp_croak_arity 2;
        @_ = ($_[1], $_[0]);
        goto &$f
    }
}

TEST {
    flip(sub { $_[0] / $_[1] })->(2, 3)
}
3 / 2;

# same as flip but pass a 3rd argument unchanged (flip 2 in 3)
sub flip2of3 {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        @_ == 3 or fp_croak_arity 3;
        @_ = ($_[1], $_[0], $_[2]);
        goto &$f
    }
}

sub rot3right {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        @_ == 3 or fp_croak_arity 3;
        @_ = ($_[2], $_[0], $_[1]);
        goto &$f
    }
}

sub rot3left {
    @_ == 1 or fp_croak_arity 1;
    my ($f) = @_;
    sub {
        @_ == 3 or fp_croak_arity 3;
        @_ = ($_[1], $_[2], $_[0]);
        goto &$f
    }
}

1
