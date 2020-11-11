#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Interface - protocol for an interface

=head1 SYNOPSIS

=head1 DESCRIPTION

An interface is just a named base type that other types implement. Its
purpose is:

1. to be used as a base type to declare a particular behaviour of the
   new type, and to define what that behaviour entails (currently just
   a set of method names that are expected to be implemented)

2. to have the defined behaviour (the set of methods) checked at load
   time of any module that implements the interface, and issue a
   warning if anything is missing.

3. to allow code to check at runtime whether objects conform to an
   interface (early dynamic error detection)

Point (2) is implemented by `FP::Struct`: when defining a class via
`FP::Struct`, each given parent class is checked for the
implementation of a method `FP_Interface__method_names` via
`can()`. This method, if present, is supposed to ignore arguments and
return a list of the names of the set of methods that is required to
implement the interface.  This method is called once at load time of
each module that defines such a class.

=head1 FUTURE / TODO

Not only declare and check the method names, but also the arity (how
many arguments it takes), argument names, and, once FP::Types is done,
optionally types.

At that point, offer more methods for introspection (IDE support).

Extend to generic functions that support the same "methods" on
unblessed references or non-reference values.

Perhaps (given some reason) rename FP::Abstract::* to FP::Protocol::*.

=head1 SEE ALSO

L<FP::Interfaces>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Abstract::Interface;

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub FP_Interface__method_names {
    my $class = shift;
    # If we're extending another interface (not the case here though),
    # we need to merge its interface definition with ours:
    ((), $class->SUPER::FP_Interface__method_names)
}

1
