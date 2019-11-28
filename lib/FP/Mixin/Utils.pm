#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Mixin::Utils - utility methods

=head1 SYNOPSIS

    use base 'FP::Mixin::Utils'; # or use parent or whatever

=head1 DESCRIPTION

Methods that can be useful to have on some classes or protocols.

Currently implemented:

C<F()>: call `F` from `FP::Stream` (useful in the repl to fully force
a data structure)

=head1 SEE ALSO

L<FP::Abstract::Show> -- uses this

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Mixin::Utils;

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub F {
    require FP::Stream;
    goto \&FP::Stream::F
}


1
