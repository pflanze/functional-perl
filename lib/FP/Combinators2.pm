#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Combinators2 - more function combinators

=head1 SYNOPSIS

    use FP::Combinators2 ":all";
    use FP::Array qw(array); use FP::Equal ":all";

    my $ra = right_associate_(*array, 0);
    is_equal $ra->(qw(a b c d)),
             ['a', ['b', ['c', 'd']]];
    is_equal $ra->(qw(a b)), ['a', 'b'];
    is_equal $ra->(qw(a)), 'a';
    is_equal $ra->(), 0;

    my $la = left_associate_(*array, 0);
    is_equal $la->(qw(a b c d)),
             [[['a', 'b'], 'c'], 'd'];
    is_equal $la->(qw(a b)), ['a', 'b'];
    is_equal $la->(qw(a)), 'a';
    is_equal $la->(), 0;


=head1 DESCRIPTION

This is an extension of L<FP::Combinators> for functions that need
more dependencies and can't be put into the former because of circular
dependencies.

=head1 SEE ALSO

L<FP::Combinators>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Combinators2;
@ISA = "Exporter";
require Exporter;
@EXPORT    = qw();
@EXPORT_OK = qw(
    right_associate_
    left_associate_);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

#use Chj::TEST;
use FP::PureArray;
use FP::Combinators qw(flip);

sub right_associate_ {
    @_ == 2 or die "wrong number of arguments";
    my ($op, $noop) = @_;
    sub {
        @_
            ? do {
            my $init = pop;
            purearray(@_)->fold_right($op, $init)
            }
            : $noop
    }
}

sub left_associate_ {
    @_ == 2 or die "wrong number of arguments";
    my ($op, $noop) = @_;
    my $op2 = flip $op;
    sub {
        @_
            ? do {
            my $init = shift;
            purearray(@_)->fold($op2, $init)
            }
            : $noop
    }
}

1
