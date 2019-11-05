#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
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
use FP::Array_sort qw(on_maybe);
use FP::Lazy;

use Chj::NamespaceCleanAbove;

# XXX these don't weaken the caller arguments, thus will leak for
# streams. How to solve this (and not copy-paste-adapt the methods
# manually) without fixing perl?

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

# XXX and on top of that, these return a lazy result even if the input
# isn't; related to the above issue. Find solution for both.

# unlike strings_join which returns a single string, this builds a new
# sequence with the given value between all elements of the original
# sequence

# (XX only works computationally efficient for *some* sequences;
# introduce an FP::IterativeSequence or so and move it there?)
sub join {
    @_==2 or die "wrong number of arguments";
    my ($self, $value)=@_;
    # (should we recurse locally like most sequence functions? Or is
    # it actually a good idea to call the method on the rest (for
    # improper_listS, but once we introduce a `cons` method on
    # PureArray etc. that won't happen anymore?)?)
    lazy {
	$self->is_null ? $self :
	  do {
	      my ($v,$rest)= $self->first_and_rest;
	      $rest->is_null ? $self
		: FP::List::cons ($v, FP::List::cons ($value, $rest->join($value)))
	  }
    }
}



# XX better name?
sub extreme {
    @_==2 or die "wrong number of arguments";
    my ($self, $cmp)=@_;
    # XXX: fold_right is good for FP::Stream streaming. left fold will
    # be better for FP::List. How? Add fold_left for explicit left
    # folding and make fold chose the preferred solution for
    # order-irrelevant folding?
    $self->rest->fold
      (sub {
	   my ($v, $res)=@_;
	   &$cmp($v, $res) ? $v : $res
       },
       $self->first);
}

sub min {
    @_==1 or @_==2 or die "wrong number of arguments";
    my ($self, $maybe_extract)=@_;
    $self->extreme(on_maybe $maybe_extract, sub { $_[0] < $_[1] })
}

sub max {
    @_==1 or @_==2 or die "wrong number of arguments";
    my ($self, $maybe_extract)=@_;
    $self->extreme(on_maybe $maybe_extract, sub { $_[0] > $_[1] })
}

sub minmax {
    @_==1 or @_==2 or die "wrong number of arguments";
    my ($self, $maybe_extract)=@_;
    # XXX same comment as in `extreme`
    @{$self->rest->fold
	(defined $maybe_extract ?
	 sub {
	     my ($v, $res)=@_;
	     my ($min,$max)= @$res;
	     my $v_ = &$maybe_extract($v);
	     [ $v_ < &$maybe_extract($min) ? $v : $min,
	       $v_ > &$maybe_extract($max) ? $v : $max ]
	 }
	 :
	 sub {
	     my ($v, $res)=@_;
	     my ($min,$max)= @$res;
	     [ $v < $min ? $v : $min,
	       $v > $max ? $v : $max ]
	 },
	 [$self->first, $self->first])}
}


sub subsection {
    @_==3 or die "wrong number of arguments";
    my ($self, $i0, $i1)=@_;
    # XXX same comment as in `extreme`
    $self->drop($i0)->take($i1 - $i0)
}


_END_
