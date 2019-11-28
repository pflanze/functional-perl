#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Abstract::Pure - functional purity protocol

=head1 SYNOPSIS

    use FP::List;
    my $v= list(1); # or any other data structure that implements
                    # FP::Abstract::Pure
    is UNIVERSAL::isa($v, "FP::Abstract::Pure"), 1;
    # Or use Safe::Isa instead of UNIVERSAL::isa, but I don't understand
    # why overriding isa is useful (why fake inherit as opposed to real
    # inheriting but then shadowing what needs to be shadowed? NEXT method
    # and that needs to be supported in mock classes? TODO figure out.)

    # but usually:
    use FP::Predicates;
    is_pure ($v) # true if $v does (officially) not support mutation

=head1 DESCRIPTION

Base class for all data structures that don't allow mutation (by
ordinary programs), i.e. are
L<persistent|https://en.wikipedia.org/wiki/Persistent_data_structure>.

More precisely, those objects that don't have methods that when called
make other methods non-functions.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Abstract::Pure;

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub FP_Interface__method_names {
    ()
}


1
