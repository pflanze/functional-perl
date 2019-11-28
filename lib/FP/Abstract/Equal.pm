#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Equal - equality protocol

=head1 SYNOPSIS

    package FPEqualExample::Foo {
        sub new { my $class= shift; bless [@_], $class }
        sub FP_Equal_equal {
            my ($a, $b)=@_;
            # If you know you've got numbers in here only:
            $$a[0] == $$b[0]
            # For generic values, you would instead:
            #use FP::Equal;
            #equal($$a[0], $$b[0])
        }
    }

    use FP::Equal qw(equal); use FP::List;

    ok equal( list(10,20,30)->map
                  (sub{ equal(FPEqualExample::Foo->new(20),
                              FPEqualExample::Foo->new($_[0])) }),
              list('', 1, ''));

=head1 DESCRIPTION

Objects implementing this protocol can be compared using the functions
from `FP::Equal`, primarily `equal`.

`equal` forces promises before doing further comparisons or passing
them to `FP_Equal_equal` (only the immediate layer, not
deeply). `FP_Equal_equal` is only ever called with the two arguments
(self and one method argument) being references of, currently, the
same type (`equal` handles the other cases internally) (TODO: how to
handle subtypes?). In better(?) words, `FP_Equal_equal`
implementations can rely on the second argument supporting the same
operations that the first one does (TODO: even into the future once
accepting subtyping?  This is *alpha*.) Likewise, `FP_Equal_equal` is
not called if the arguments are both the same reference (in this case
`equal` simply returns true).

=head1 TODO

Handle circular data structures.

=head1 SEE ALSO

L<FP::Equal>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Abstract::Equal;

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub FP_Interface__method_names {
    ("FP_Equal_equal")
}


1
