#
# Copyright 2015 by Christian Jaeger, copying@christianjaeger.ch
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
 use FP::Array 'array';

 use Chj::TEST;

 TEST { list(purearray(3,4),
             strictlist(3,4),
             list(3,4),
             stream(3,4),
             cons(3,4), # ok this can't really count as a sequence,
                        # what to do about it?
             array(3,4), # Could `autobox` change this?
             3,
	     {3=>4},
        )->map(*is_sequence)->array }
  [ 1,1,1,1,1,'','','' ];

=head1 DESCRIPTION

FP sequences are pure (no mutation is allowed, either by force
(immutability) or by convention (don't offer mutating accessors,
remind users not to mutate)).

XX This is a work in progress. More base implementations should be
moved here, etc.

=cut


package FP::Sequence;

use strict; use warnings FATAL => 'uninitialized';

use base 'FP::Pure';

use Chj::NamespaceCleanAbove;


_END_
