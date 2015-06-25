#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Sequence - base class for functional sequences

=head1 SYNOPSIS

=head1 DESCRIPTION

FP sequences are pure (no mutation is allowed, either by force
(immutability) or by convention (don't offer mutating accessors,
remind users not to mutate)).

They offer a set of methods that can be overridden. Some methods are
implemented in terms of others, e.g. `car` is implemented as calling
`first`, so overriding `first` is enough to cover both (and more).

XX This is a work in progress. More base implementations should be
moved here, etc.

=cut


package FP::Sequence;

@EXPORT=qw(is_sequence);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use FP::Pure;
our @ISA= qw(FP::Pure);

use FP::Ops "the_method";

use Chj::NamespaceCleanAbove;

# Bad, can't be cleaned but now it's a method, too
sub is_sequence ($) {
    length ref $_[0] and UNIVERSAL::isa($_[0], __PACKAGE__)
}

# EXPORT HACK
# to make it possible to use this package both for OO and exports
require Exporter;
*import= *Exporter::import; # needs to stay around as a method, can't
                            # be cleaned. Did I say this is a hack?


#*car= the_method "first";
#*cdr= the_method "rest";
# XX but should these even be part of the API? Perhaps not: only Pairs
# will support them then. As makes sense!


_END_
