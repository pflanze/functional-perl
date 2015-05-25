#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

FP::OrderedCollection

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package FP::OrderedCollection;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use FP::Predicates;
use FP::Stream qw(subarray2stream subarray2stream_reverse  stream2array);
use FP::Lazy;
use FP::List;

use Chj::Struct
  [[\&is_array, "array"],
   [\&is_hash, "hash"]];

sub new_from_array {
    my $cl=shift;
    @_==1 or die;
    my ($a)=@_;
    my %h;
    for my $i (0..$#$a) {
	$h{$$a[$i]}= $i;
    }
    $cl->new ($a,\%h)
}

sub new_from_values {
    my $cl=shift;
    $cl->new_from_array([@_])
}

sub contains {
    my $s=shift;
    @_==1 or die;
    exists $$s{hash}{$_[0]}
}

sub maybe_position {
    my $s=shift;
    @_==1 or die;
    $$s{hash}{$_[0]}
}

sub perhaps_following {
    my $s=shift;
    my $i= $s->maybe_position(@_) // return;
    subarray2stream($$s{array}, $i+1)
}

sub perhaps_previous {
    my $s=shift;
    my $i= $s->maybe_position(@_) // return;
    subarray2stream_reverse($$s{array}, $i-1)
}

sub maybe_next {
    my $s=shift;
    my ($l)= $s->perhaps_following (@_) or return undef;
    $l= force ($l);
    is_null $l ? undef : car $l
}

sub maybe_prev {
    my $s=shift;
    my ($l)= $s->perhaps_previous (@_) or return undef;
    $l= force ($l);
    is_null $l ? undef : car $l
}


TEST {
    our $c= FP::OrderedCollection->new_from_values(qw(a b c f));
    $c->contains ("a")
} 1;

TEST {
    our $c->contains ("q")
} '';

TEST {
    our $c->maybe_position ("1")
} undef;

TEST {
    our $c->maybe_position ("f")
} 3;

TEST { [ our $c->perhaps_following ("xx")] }
  [];
TEST { stream2array( our $c->perhaps_following ("c")) }
  [ 'f' ];
TEST { stream2array( our $c->perhaps_following ("b")) }
  [ 'c', 'f' ];
TEST { stream2array( our $c->perhaps_previous ("c")) }
  [ 'b', 'a' ];

TEST { our $c->maybe_prev("c") }
  'b';
TEST { our $c->maybe_prev("a") }
  undef;
TEST { our $c->maybe_prev("xx") }
  undef;
TEST { our $c->maybe_next("a") }
  'b';
TEST { our $c->maybe_next("f") }
  undef;


_END_
