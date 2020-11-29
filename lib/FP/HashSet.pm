#
# Copyright (c) 2013-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::HashSet - set operations for hash tables

=head1 SYNOPSIS

    use FP::Equal 'is_equal';
    use FP::HashSet; # ":all";

    my $A = array_to_hashset ["a","b","c"];
    my $B = array_to_hashset ["a","c","d"];
    is_equal hashset_to_array(hashset_union($A,$B)),
             ["a","b","c","d"];
    is_equal hashset_to_array(hashset_intersection($A,$B)),
             ["a","c"];
    is_equal hashset_to_array(hashset_difference($A,$B)),
             ["b"];
    ok not hashset_is_subset($B,$A);
    ok hashset_is_subset(+{b => 1},$A);
    is hashset_size($A), 3;
    ok not hashset_empty($A);
    ok hashset_empty(+{});
    #hashset_keys_unsorted($A) # ("a","b","c") or in another sort order;
                               # *keys* not values, hence always strings.
    is_equal [hashset_keys ($A)],
             [("a","b","c")]; # (always sorted)

    # a la diff tool:
    is_equal hashset_diff($A,$B), +{ b => "-", d => "+" };

    # to treat a hashset as a function:
    my $f = hashset_to_predicate ($A);
    ok $f->("a");


=head1 DESCRIPTION

Hashsets are hash tables that are expected to have keys representing
the values unambiguously (FP::Array::array_to_hashset will just
use the stringification).

Note that hashset_to_array will use the *values* of the hashes, not the
keys.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::HashSet;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(array_to_hashset
    array_to_lchashset
    hashset_to_array
    hashset_to_predicate
    hashset_keys
    hashset_keys_unsorted
    hashset_union
    hashset_union_defined
    hashset_intersection
    hashset_difference
    hashset_is_subset
    hashset_size
    hashset_empty
    hashset_diff
);
our @EXPORT_OK   = qw(hashset_add_hashset_d);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::TEST;
use FP::Carp;

sub array_to_hashset {
    @_ == 1 or fp_croak_nargs 1;
    +{ map { $_ => $_ } @{ $_[0] } }
}

sub array_to_lchashset {
    @_ == 1 or fp_croak_nargs 1;
    +{ map { lc($_) => $_ } @{ $_[0] } }
}

sub hashset_to_array {
    @_ == 1 or fp_croak_nargs 1;
    [sort values %{ $_[0] }]
}

sub hashset_to_predicate {
    @_ == 1 or fp_croak_nargs 1;
    my ($s) = @_;
    sub {
        @_ == 1 or fp_croak_nargs 1;
        exists $$s{ $_[0] }
    }
}

sub hashset_keys_unsorted {
    @_ == 1 or fp_croak_nargs 1;
    keys %{ $_[0] }
}

sub hashset_keys {
    @_ == 1 or fp_croak_nargs 1;
    sort keys %{ $_[0] }
}

sub hashset_add_hashset_d ($ $) {
    my ($r, $s) = @_;
    for (keys %$s) {
        $$r{$_} = $$s{$_} unless exists $$r{$_};
    }
}

sub hashset_union {
    my %r;
    hashset_add_hashset_d(\%r, $_) for @_;
    \%r
}

# same as hashset_union but check definedness, not existence

sub hashset_add_hashset_defined_d ($ $) {
    my ($r, $s) = @_;
    for (keys %$s) {
        $$r{$_} = $$s{$_} unless defined $$r{$_};
    }
}

sub hashset_union_defined {
    my %r;
    hashset_add_hashset_defined_d(\%r, $_) for @_;
    \%r
}

# /same

sub hashset_intersection ($ $) {
    my ($a, $b) = @_;
    my %r;
    for (keys %$a) {
        $r{$_} = $$b{$_} if exists $$b{$_};
    }
    \%r
}

sub hashset_difference ($ $) {
    my ($a, $b) = @_;
    my %r;
    for (keys %$a) {
        $r{$_} = $$a{$_} unless exists $$b{$_};
    }
    \%r
}

sub hashset_is_subset ($ $) {
    my ($subset, $set) = @_;
    my %r;
    for (keys %$subset) {
        return 0 unless exists $$set{$_};
    }
    1
}

sub hashset_size {
    @_ == 1 or fp_croak_nargs 1;
    scalar keys %{ $_[0] }
}

sub hashset_empty {
    @_ == 1 or fp_croak_nargs 1;
    not keys %{ $_[0] }
}

sub hashset_diff ($ $) {
    my ($a, $b) = @_;
    my %r;
    for (keys %$a) {
        $r{$_} = "-" unless exists $$b{$_};
    }
    for (keys %$b) {
        $r{$_} = "+" unless exists $$a{$_};
    }
    \%r
}

{
    my $A = array_to_hashset ["a", "b", "c"];
    my $B = array_to_hashset ["a", "c", "d"];
    TEST { hashset_to_array hashset_union($A, $B) }
    ["a", "b", "c", "d"];
    TEST { hashset_to_array hashset_intersection($A, $B) }
    ["a", "c"];
    TEST { hashset_to_array hashset_difference($A, $B) }
    ["b"];
    TEST { hashset_is_subset($B, $A) }
    0;
    TEST { hashset_is_subset(+{ b => 1 }, $A) }
    1;
    TEST { hashset_size($A) }
    3;
    TEST { hashset_empty($A) }
    '';
    TEST { hashset_empty(+{}) }
    1;
    TEST { hashset_diff($A, $B) }
    +{ b => "-", d => "+" };
    my $f = hashset_to_predicate($A);
    TEST { $f->("a") }
    1;
    TEST { $f->("x") }
    '';
}

1
