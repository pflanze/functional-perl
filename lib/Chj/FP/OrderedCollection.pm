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
use Chj::FP2::Lazy;
use Chj::FP2::List;

use Chj::Struct
  [[\&arrayP, "array"],
   [\&hashP, "hash"]];

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
    $l= Force ($l) // return undef; # parens are required. Wow Perl.
    car $l
}

sub maybe_prev {
    my $s=shift;
    my ($l)= $s->perhaps_previous (@_) or return undef;
    $l= Force ($l) // return undef;
    car $l
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
