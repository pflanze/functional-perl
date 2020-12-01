#
# Copyright (c) 2014-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Array::Mixin

=head1 SYNOPSIS

=head1 DESCRIPTION

Used to implement array based sequences.

=head1 SEE ALSO

L<FP::PureArray>, L<FP::MutableArray>

L<FP::Array> -- definition of most functions used here

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Array::Mixin;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Carp;
use FP::Optional qw(perhaps_to_maybe);
use FP::Combinators qw (flip flip2of3 rot3right rot3left);
use FP::Array ":all";
use FP::Array_sort qw(array_sort array_sortCompare);

sub blessing {
    @_ == 1 or fp_croak_arity 1;
    my ($m) = @_;
    sub {
        my $class = ref $_[0];
        if (my ($v) = &$m(@_)) {
            $class->new_from_array($v)
        } else {
            ()
        }
    }
}

sub blessing2 {
    @_ == 1 or fp_croak_arity 1;
    my ($m) = @_;
    sub {
        my $class = ref $_[0];
        if (my ($v1, $v2) = &$m(@_)) {
            ($class->new_from_array($v1), $class->new_from_array($v2))
        } else {
            ()
        }
    }
}

sub blessing_snd {
    @_ == 1 or fp_croak_arity 1;
    my ($m) = @_;
    sub {
        my $class = ref $_[0];
        wantarray
            ? do {
            my ($v, $a) = &$m(@_);
            ($v, $class->new_from_array($a))
            }
            : $class->new_from_array((&$m(@_))[-1]);
    }
}

use Chj::NamespaceCleanAbove;

sub FP_Show_show {
    my ($s, $show) = @_;
    $s->constructor_name . "(" . join(", ", @{ array_map($show, $s) }) . ")"
}

*FP_Equal_equal = *array_equal;

sub is_proper_sequence {1}

# de-import array from FP::Array to avoid redefinition warning
BEGIN { undef *array }

sub array {
    @_ == 1 or fp_croak_arity 1;
    my $s = shift;

    # 'debless', and copy necessary as the user is entitled to mod it
    # now. (XX: might optimize if only reference left by checking the
    # refcount)
    [@$s]
}

sub list {
    @_ == 1 or fp_croak_arity 1;
    my $s = shift;
    require FP::List;    # (overhead of repeated require?)
    FP::List::array_to_list($s)
}

sub stream {
    @_ == 1 or fp_croak_arity 1;
    my $s = shift;
    require FP::Stream;    # (ditto)
    FP::Stream::array_to_stream($s)
}

sub strictlist {
    @_ == 1 or fp_croak_arity 1;
    my $s = shift;

    # XX could be more efficient via an
    # FP::StrictList::array_to_strictlist if it existed.
    FP::StrictList::strictlist(@$s)
}

sub string {
    @_ == 1 or fp_croak_arity 1;
    array_to_string $_[0]
}

sub is_null {
    @_ == 1 or fp_croak_arity 1;
    not @{ $_[0] }
}

# Do *not* provide `is_pair`, though, since this is not a pair based
# data structure? Or is the `is_null` already evil because of this and
# should be named `is_empty`?

sub values {
    @{ $_[0] }
}

*cons          = flip \&FP::List::pair;    # XX ?  Also, XXX FP::List might not
                                           # be loaded here
*first         = \&array_first;
*maybe_first   = \&array_maybe_first;
*perhaps_first = \&array_perhaps_first;
*rest          = blessing \&array_rest;
*maybe_rest   = blessing \&array_maybe_rest;
*perhaps_rest = blessing \&array_perhaps_rest;

sub first_and_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    (array_first($a), ref($a)->new_from_array(array_rest($a)))
}

# XXX ah could have used blessing_snd ^ v
sub maybe_first_and_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a ? (array_first($a), ref($a)->new_from_array(array_rest($a))) : undef
}

sub perhaps_first_and_rest {
    @_ == 1 or fp_croak_arity 1;
    my ($a) = @_;
    @$a ? (array_first($a), ref($a)->new_from_array(array_rest($a))) : ()
}
*second          = \&array_second;
*last            = \&array_last;
*ref             = \&array_ref;
*FP_Sequence_ref = *ref;
*length          = \&array_length;

sub FP_Sequence_length {
    my ($self, $prefixlen) = @_;
    $prefixlen + $self->length
}
*set                 = blessing \&array_set;
*update              = blessing \&array_update;
*push                = blessing \&array_push;
*pop                 = blessing_snd \&array_pop;
*shift               = blessing_snd \&array_shift;
*unshift             = blessing \&array_unshift;
*sub                 = blessing \&array_sub;
*take                = blessing \&array_take;
*drop                = blessing \&array_drop;
*drop_while          = blessing flip \&array_drop_while;
*take_while          = blessing flip \&array_take_while;
*take_while_and_rest = blessing2 flip \&array_take_while_and_rest;
*append              = blessing \&array_append;
*reverse             = blessing \&array_reverse;
*xone                = \&array_xone;
*perhaps_one         = \&array_perhaps_one;
*hashing_uniq        = blessing \&array_hashing_uniq;
*zip2                = blessing \&array_zip2;
*for_each            = flip \&array_for_each;
*map                 = blessing flip \&array_map;
*map_with_index      = blessing flip \&array_map_with_index;
*map_with_islast     = blessing flip \&array_map_with_islast;
*filter              = blessing flip \&array_filter;
*zip                 = blessing \&array_zip;
*fold                = rot3left \&array_fold;
*fold_right          = rot3left \&array_fold_right;
*preferred_fold      = *fold;                                        # ?
*intersperse         = blessing \&array_intersperse;
*strings_join        = \&array_strings_join;
*every               = flip \&array_every;
*any                 = flip \&array_any;
*sum                 = \&array_sum;
*hash_group_by       = \&array_to_hash_group_by;

*sort        = blessing \&array_sort;
*sortCompare = blessing \&array_sortCompare;

# XX provide them as functions, too? (prefixed with `purearray_`) (to
# avoid requiring the user to use `the_method` [and perhaps missing
# the explicit type check?])

*perhaps_find_tail = blessing flip \&array_perhaps_find_tail;
*perhaps_find      = flip \&array_perhaps_find;
*find              = perhaps_to_maybe(\&array_perhaps_find);

_END_    # Chj::NamespaceCleanAbove
