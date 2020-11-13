#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::BigInt

=head1 SYNOPSIS

    use FP::Equal 'is_equal'; use FP::Show;
    use FP::BigInt;

    is_equal ref(bigint(13)), 'Math::BigInt';
    is_equal "".(bigint(10)**20), '100000000000000000000';
    is_equal bigint(13) / bigint(10), bigint('1');

    is show(bigint(7)), "bigint('7')";

=head1 DESCRIPTION

Loads L<Math::BigInt>, monkey patches C<FP_Show_show> and
C<FP_Equal_equal> methods into it, and exports the C<bigint>
constructor function.

=head1 SEE ALSO

L<Math::BigInt>

L<FP::Abstract::Show>, L<FP::Abstract::Equal> -- implemented protocols

=cut

package FP::BigInt;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(bigint);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Math::BigInt;

#use FP::Interfaces;

sub bigint ($) {
    Math::BigInt->new($_[0])
}

package    # Monkey patching; but using long ucfirst (TODO: go all
           # uppercase(?)) method names that should never conflict with
           # anybody else's. Use case doesn't really allow for
           # subclassing. Might look into implementing some sort of
           # lexical extensions of classes at some point.
    Math::BigInt {

    sub FP_Show_show {
        my $s = shift;
        "bigint('$s')"
    }

    sub FP_Equal_equal {
        my ($a, $b) = @_;
        $a == $b
    }

    # commented out to not modify Math::BigInt's @ISA, although it
    # would be good to have for consistency.
    #FP::Interfaces::implemented qw(FP::Abstract::Show
    #                               FP::Abstract::Equal);
}

1
