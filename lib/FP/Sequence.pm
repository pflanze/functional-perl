#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Sequence - base class for functional sequences

=head1 SYNOPSIS

 use FP::Predicates "is_sequence"; # since we can't have it in
                                   # FP::Sequence
 use FP::PureArray;
 use FP::StrictList;
 use FP::List;
 use FP::Stream;

 use FP::TEST;

 TEST { list(purearray(3,4),
             strictlist(3,4),
             list(3,4),
             stream(3,4),
             cons(3,4), # ok this can't really count as a sequence,
                        # what to do about it?
             array(3,4), # Would `autobox` change this?
        )->map(*is_sequence)->array }
  [ 1,1,1,1,1,'' ];

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

use strict; use warnings FATAL => 'uninitialized';

use FP::Pure;
our @ISA= qw(FP::Pure);

#use FP::Ops "the_method";

use Chj::NamespaceCleanAbove;

#*car= the_method "first";
#*cdr= the_method "rest";
# XX but should these even be part of the API? Perhaps not: only Pairs
# will support them then. As makes sense!


_END_
