#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::SortedPureArray

=head1 SYNOPSIS

    use FP::PureArray;
    use FP::SortedPureArray;
    use FP::Equal qw(is_equal);
    use FP::Ops qw(real_cmp);

    my $a1 = purearray(10, 40, 50, 50, 60);

    # This re-blesses $a1, too ($a1 and $s1 are the same object), so
    # it's not a functional operation, but then it shouldn't be
    # damaging either, or so one hopes...:
    my $s1 = $a1->as_sorted_by(\&real_cmp);

    is_equal [ $s1->perhaps_binsearch(40) ], [40];
    is_equal [ $s1->perhaps_binsearch(41) ], [];
    ok $s1->checks_ok;

    *real_sortedpurearray = sortedpurearray_by(\&real_cmp);
    my $vs = real_sortedpurearray(10, 40, 50, 50, 60);

    is_equal [ $vs->perhaps_binsearch(40) ], [40];
    is_equal [ $vs->perhaps_binsearch(41) ], [];
    ok $vs->checks_ok;

    # For performance reasons, the constructor does *not* sort the
    # values or check whether the values are actually sorted.
    my $bad = real_sortedpurearray(10, 50, 40, 60);

    # But that check can be run explicitly:
    ok not $bad->checks_ok;

    ok real_sortedpurearray(10, 50, 50, 60)->checks_ok;

    is sortedpurearray_by(\&real_cmp)->(10,10)->checks_ok, 1;
    is sortedpurearray_by(\&real_cmp)->(20,10)->checks_ok, '';
    is sortedpurearray_by(\&real_cmp)->(3,10)->checks_ok, 1;

=head1 DESCRIPTION

A sorted L<FP::PureArray>. Has all the methods of the latter, plus
currently just `perhaps_binsearch`.

So, this is very much unfinished and deserves more methods and
constructors, as well as possibly a protocol (FP::Abstract::*).

=head1 SEE ALSO

L<FP::PureArray>, that this inherits from.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::SortedPureArray;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
use Exporter "import";

our @EXPORT      = qw(sortedpurearray_by);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::PureArray;
use FP::Carp;

sub sortedpurearray_by {
    @_ == 1 or fp_croak_arity 1;
    my ($cmp) = @_;
    sub {
        purearray(@_)->as_sorted_by($cmp)
    }
}

package FP::_::SortedPureArray {
    our @ISA = qw(FP::_::PureArray);

    use List::BinarySearch qw(binsearch);
    use FP::Carp;
    use FP::Array qw(array_map);
    use FP::Docstring;

    # Implement the additional field via external hashtable, so that
    # array accesses and super class methods all work without
    # indirection. I expect this to be the right trade off.

    my %sorted_by_cmp;    # pointer => subroutine

    sub new_from_purearray {
        @_ == 3 or fp_croak_arity 3;
        my ($class, $a, $sorted_by_cmp) = @_;

        # Not so read-only after all... evil?
        Internals::SvREADONLY @$a, 0;
        bless $a, $class;
        Internals::SvREADONLY @$a, 1;
        $sorted_by_cmp{ $a +0 } = $sorted_by_cmp;
        $a
    }

    sub checks_ok {
        @_ == 1 or fp_croak_arity 1;
        __ 'Verifies if the array *is* sorted as it is claimed to be,
            returns true iff it is.';
        my ($self) = @_;
        my $len = @$self;
        return 1 if $len == 0;
        my $cmp = $sorted_by_cmp{ $self +0 };
        my $v   = $self->[0];

        for (1 .. $len - 1) {
            my $v2 = $self->[$_];
            my $c  = $cmp->($v, $v2);
            return '' unless $c <= 0;
            $v = $v2;
        }
        1
    }

    sub DESTROY {
        my $self = shift;
        delete $sorted_by_cmp{ $self +0 };
    }

    sub FP_Show_show {
        my ($self, $show) = @_;
        "sortedpurearray_by("
            . $show->($sorted_by_cmp{ $self +0 }) . ")->("
            . join(", ", @{ array_map($show, $self) }) . ")"
    }

    sub perhaps_binsearch {
        @_ == 2 or fp_croak_arity 2;
        __ '$self->perhaps_binsearch($element): searches using the
            comparator stored with $self';
        my ($self, $element) = @_;

        if (
            defined(
                my $index
                    = binsearch { $sorted_by_cmp{ $self +0 }->($a, $b) }
                $element, @$self
            )
            )
        {
            $self->[$index]
        } else {
            ()
        }
    }
}

1
