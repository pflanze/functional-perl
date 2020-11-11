#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::OrderedCollection

=head1 SYNOPSIS

    use FP::Equal 'is_equal'; use FP::Stream;
    use FP::OrderedCollection;

    my $c = FP::OrderedCollection->new_from_values(qw(a b c f));
    ok $c->contains("a");
    ok not $c->contains("q");
    is $c->maybe_position("1"), undef;
    is $c->maybe_position("f"), 3;
    is_equal [ $c->perhaps_following ("xx")], [];
    is_equal $c->perhaps_following("c"), stream('f');
    is_equal $c->perhaps_following("b"), stream('c', 'f');
    is_equal $c->perhaps_previous("c"), stream('b', 'a');
    is $c->maybe_prev("c"), 'b';
    is $c->maybe_prev("a"), undef;
    is $c->maybe_prev("xx"), undef;
    is $c->maybe_next("a"), 'b';
    is $c->maybe_next("f"), undef;

=head1 DESCRIPTION

=head1 SEE ALSO

Implements: L<FP::Abstract::Pure>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::OrderedCollection;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Predicates;
use FP::Stream qw(subarray_to_stream subarray_to_stream_reverse  stream_to_array);
use FP::Lazy;
use FP::List;

use FP::Struct
  [[\&is_array, "array"],
   [\&is_hash, "hash"]],
    'FP::Abstract::Pure';


# Unsafe: assumes that the given array is never mutated after
# constructing the OrderedCollection
sub unsafe_new_from_array {
    my $cl = shift;
    @_ == 1 or die "wrong number of arguments";
    my ($a) = @_;
    my %h;
    for my $i (0..$#$a) {
        $h{$$a[$i]} = $i;
    }
    $cl->new ($a,\%h)
}

sub new_from_array {
    my $cl = shift;
    @_ == 1 or die "wrong number of arguments";
    my ($a) = @_;
    $cl->unsafe_new_from_array ([@$a])
}

sub new_from_values {
    my $cl = shift;
    $cl->unsafe_new_from_array([@_])
}

sub contains {
    my $s = shift;
    @_ == 1 or die "wrong number of arguments";
    exists $$s{hash}{$_[0]}
}

sub maybe_position {
    my $s = shift;
    @_ == 1 or die "wrong number of arguments";
    $$s{hash}{$_[0]}
}

sub perhaps_following {
    my $s = shift;
    my $i = $s->maybe_position(@_) // return;
    subarray_to_stream($$s{array}, $i+1)
}

sub perhaps_previous {
    my $s = shift;
    my $i = $s->maybe_position(@_) // return;
    subarray_to_stream_reverse($$s{array}, $i-1)
}

sub maybe_next {
    my $s = shift;
    my ($l) = $s->perhaps_following (@_) or return undef;
    $l = force ($l);
    is_null $l ? undef : car $l
}

sub maybe_prev {
    my $s = shift;
    my ($l) = $s->perhaps_previous (@_) or return undef;
    $l = force ($l);
    is_null $l ? undef : car $l
}


_END_
