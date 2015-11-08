#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
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

Also, methods that are only implemented here are inconsistent in that
they can't be imported as functions from any module. Should we really
move functions over as plain wrappers across method calls
(only?). Although perhaps it's fair to (only) have those functions
importable under a type specific name that have type specific
implementations.


=cut


package FP::Sequence;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use base 'FP::Pure';
require FP::List; # "use"ing it would create a circular dependency

use Chj::NamespaceCleanAbove;

sub flatten {
    @_==1 or @_==2 or die "wrong number of arguments";
    my ($self, $perhaps_tail)=@_;
    $self->fold_right
      (sub {
	   my ($v, $rest)=@_;
	   $v->append($rest)
       },
       @_==2 ? $perhaps_tail : FP::List::null());
}


_END_
