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

=head1 DESCRIPTION

A sorted L<FP::PureArray>. Has all the methods of the latter, plus
currently just `perhaps_binsearch`.

So, this is very much unfinished and deserves more methods and
constructors, as well as possibly a protocol (FP::Abstract::*).

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
