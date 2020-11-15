#
# Copyright (c) 2019-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::MutableArray

=head1 SYNOPSIS

    use FP::MutableArray;
    use FP::Div 'inc';

    my $a = mutablearray(1,4,5)->map(*inc);
    is $a->sum, 13;
    $a->[0]++;
    is $a->sum, 14;

    # They can be turned into immutable ones:
    my $b = $a->pure;
    like( (eval { $b->[0]++; 1 } || $@),
          qr/^Modification of a read-only value attempted/);

    # Although this really consumes the original array, which is now
    # immutable, too:
    like( (eval { $a->[0]++; 1 } || $@),
          qr/^Modification of a read-only value attempted/);

    is $a->sum, 14;

    is( FP::_::MutableArray->null == FP::_::MutableArray->null, '' );

=head1 DESCRIPTION

Native Perl arrays but blessed so that they can follow the sequences
protocol.

=head1 SEE ALSO

Implements: L<FP::Abstract::Sequence>, L<FP::Abstract::Equal>,
L<FP::Abstract::Show>

L<FP::PureArray>, L<FP::Array>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::MutableArray;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(is_mutablearray mutablearray array_to_mutablearray);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Scalar::Util 'blessed';

sub is_mutablearray ($) {
    my ($v) = @_;
    my $r = blessed($v) // return;
    ($r eq "FP::_::MutableArray" or $v->isa("FP::_::MutableArray"))
}

sub mutablearray {
    FP::_::MutableArray->new_from_array([@_])
}

sub array_to_purearray ($) {
    FP::_::MutableArray->new_from_array($_[0])
}

package FP::_::MutableArray {
    use base qw(FP::Array::Mixin);
    use FP::Interfaces;
    use Carp;
    use Chj::NamespaceCleanAbove;

    sub new_from_array {
        @_ == 2 or die "wrong number of arguments";
        my ($class, $a) = @_;
        bless $a, $class
    }

    sub mutablearray {
        @_ == 1 or die "wrong number of arguments";
        my $s = shift;
        $s
    }

    sub purearray {
        @_ == 1 or die "wrong number of arguments";
        my $s = shift;
        FP::_::PureArray->new_from_array($s)
    }

    sub null {
        my $proto = shift;
        my $class = ref($proto) || $proto;

        # can't cache this since mutation is allowed!:
        $class->new_from_array([])
    }

    sub constructor_name {
        "mutablearray"
    }

    sub pure {
        @_ == 1 or die "wrong number of arguments";

        # same as `array_to_purearray`
        require FP::PureArray;    # cost?
        FP::_::PureArray->new_from_array($_[0])
    }

    our $unsafe_mutable_warned = 0;

    sub unsafe_mutable {
        @_ == 1 or die "wrong number of arguments";
        my $a = shift;
        carp "is already mutable" unless $unsafe_mutable_warned++;
        $a
    }

    _END_;    # Chj::NamespaceCleanAbove

    FP::Interfaces::implemented qw(
        FP::Abstract::Sequence
        FP::Abstract::Equal
        FP::Abstract::Show);
}

1
