#
# Copyright (c) 2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Compare - comparison protocol

=head1 SYNOPSIS

    package FPCompareExample::Foo {
        use FP::Struct ["num"];
        sub FP_Compare_compare {
            my ($a, $b) = @_;
            # let's make the default sort order reversed for the sake
            # of a more interesting example:
            $b->num cmp $a->num
        }
        _END_
    }

    use FP::PureArray; use FP::Ops 'the_method'; use FP::Equal qw(is_equal);
    is_equal( purearray(2,3,-7,4,2,8)
                 ->map(\&FPCompareExample::Foo::c::Foo)
                    ->sortCompare
                       ->map(the_method("num")),
              purearray(8, 4, 3, 2, 2, -7));

=head1 DESCRIPTION

Objects implementing this protocol can be ordered unambiguously.

The `$a->FP_Compare_compare($b)` returns -1 if $a is to be ordered before
$b (is smaller), 0 if they are to be ordered into the same position, 1
if $a is to be ordered after $b.

This method is used for the default sort order by the `sort` method
offered on sequences.

=head1 SEE ALSO

L<FP::Compare>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Abstract::Compare;

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub FP_Interface__method_names {
    ("FP_Compare_compare")
}


1
