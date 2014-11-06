#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::OrderedCollection

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::OrderedCollection;

use strict; use warnings FATAL => 'uninitialized';

use Chj::TEST;
use Chj::FP::Predicates;
use Chj::FP2::Stream qw(subarray2stream subarray2stream_reverse  stream2array);

use Chj::Struct
  [[\&arrayP, "array"],
   [\&hashP, "hash"]];

sub new_from_values {
    my $cl=shift;
    my %h;
    for my $i (0..$#_) {
	$h{$_[$i]}= $i;
    }
    $cl->new ([@_],\%h)
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

sub maybe_following {
    my $s=shift;
    my $i= $s->maybe_position(@_) // return undef;
    subarray2stream($$s{array}, $i+1)
}

sub maybe_previous {
    my $s=shift;
    my $i= $s->maybe_position(@_) // return undef;
    subarray2stream_reverse($$s{array}, $i-1)
}


TEST {
    our $c= Chj::FP::OrderedCollection->new_from_values(qw(a b c f));
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

TEST { stream2array( our $c->maybe_following ("xx")) }
  []; # ahh, XXX because undef is the same as the empty stream
TEST { stream2array( our $c->maybe_following ("c")) }
  [ 'f' ];
TEST { stream2array( our $c->maybe_following ("b")) }
  [ 'c', 'f' ];
TEST { stream2array( our $c->maybe_previous ("c")) }
  [ 'b', 'a' ];


_END_
