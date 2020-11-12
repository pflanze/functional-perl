#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Hash

=head1 SYNOPSIS

    use FP::Equal 'is_equal';
    use FP::Hash;

    my $a = {a => 1, b => 2};
    my $b = hash_set($a, "b", 3);
    my $c = hash_delete($b, "a");
    if (my ($v) = hash_perhaps_ref ($c, "x")) {
       is_equal $v, "XXX";
    }
    is_equal hash_update($a, 'a', sub { $_[0]+10 }),
             +{ a => 11, b => 2 };
    is_equal hash_update($a, 'x', sub { [@_] }),
             +{ a => 1, b => 2, x => [] };

    # The function passed to hash_update is run in list context! Empty
    # list means, delete the item.
    my $e = hash_update $a, 'a', sub { () };
    is_equal $e, +{ b => 2 };

    is_equal $c, +{b => 3};
    is_equal $a, +{a => 1, b => 2};

    is_equal subhash({a => 10, b => 11, c => 12}, "a", "c"),
             +{a => 10, c => 12};


=head1 DESCRIPTION

Provides pure functions on hash tables. Note though that hash table
updates simply copy the whole hash table, thus you may easily get bad
computational complexity. (If you really care about that, and not so
much about interoperability with other Perl code, perhaps port a
functional hash tables implementation (like the one used by Clojure)?)


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Hash;
@ISA = "Exporter";
require Exporter;
@EXPORT
    = qw(hash_set hash_perhaps_ref hash_maybe_ref hash_xref hash_ref_or hash_cache
    hash_delete hash_update hash_diff
    hash_length
    subhash
    hashes_keys $empty_hash
    hash2_set
);
@EXPORT_OK   = qw();
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Chj::TEST;

#use Const::Fast;
#const my %empty_hash;

# since Const::Fast doesn't (currently) buy anything more than
# Hash::Util's lock_hash, use the latter for less dependencies.
use Hash::Util 'lock_hash';
my %empty_hash;
lock_hash %empty_hash;

our $empty_hash = \%empty_hash;

#TEST_EXCEPTION { $$empty_hash{a} }
#  undef;
#
# Aw, that also gives 'Attempt to access disallowed key \'a\' in a
# restricted hash'.  man Const::Fast says: "You have to use exists
# $a{baz} instead. This is a limitation of perl that can hopefully be
# solved in the future."

TEST_EXCEPTION { $$empty_hash{a} = 1 }
'Attempt to access disallowed key \'a\' in a restricted hash';

sub hash_set ($$$) {
    my ($h, $k, $v) = @_;
    my $h2 = +{%$h};
    $$h2{$k} = $v;
    $h2
}

my $h = {a => 1, b => 2};
TEST { hash_set $h, b => 3 }
+{'a' => 1, 'b' => 3};
TEST {$h}
+{'a' => 1, 'b' => 2};

sub hash_delete ($$) {
    my ($h, $k) = @_;
    my $h2 = +{%$h};
    delete $$h2{$k};
    $h2
}

sub hash_update ($$$) {
    my ($h, $k, $fn) = @_;
    my $h2 = +{%$h};
    if (my ($v) = &$fn(exists $$h{$k} ? $$h{$k} : ())) {
        $$h2{$k} = $v;
    }
    else {
        delete $$h2{$k}
    }
    $h2
}

TEST {
    hash_update $h, 'a', sub { $_[0] + 10 }
}
+{a => 11, b => 2};
TEST {
    hash_update $h, 'x', sub { [@_] }
}
+{a => 1, b => 2, x => []};
TEST {
    hash_update $h, 'a', sub { () }
}
+{b => 2};

sub hash_length ($) {
    my ($h) = @_;
    scalar keys %$h
}

TEST { hash_length +{} } 0;
TEST { hash_length +{a => 4, b => 5} } 2;

sub hash_perhaps_ref ($$) {
    my ($h, $k) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    }
    else { () }
}

# difference of the following to just $$h{$k} is that it won't die on
# locked hashes
sub hash_maybe_ref ($$) {
    my ($h, $k) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    }
    else {
        undef
    }
}

sub hash_xref ($$) {
    my ($h, $k) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    }
    else {
        die "unbound table key";    # no such key. unknown key. unbound
                                    # hash key. ?
    }
}

sub hash_ref_or ($$$) {
    my ($h, $k, $other) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    }
    else {
        $other
    }
}

sub hash_cache ($$$) {

    # only allowing for scalar context
    my ($h, $k, $generate) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    }
    else {
        $$h{$k} = &$generate()
    }
}

# looking for definedness, not exists. Ok? Also, only handles strings
# as values.
sub hash_diff ($$) {
    my ($h1, $h2) = @_;
    my $changes = {};
    for my $key (keys %$h2) {
        my $old = $$h1{$key};
        my $new = $$h2{$key};
        if (defined($old) and defined($new)) {
            $$changes{$key} = ($old eq $new) ? "unchanged" : "changed";
        }
        else {
            $$changes{$key} = defined($old) ? "deleted" : "added";
        }
    }
    for my $key (keys %$h1) {
        next if defined $$h2{$key};
        $$changes{$key} = "deleted";
    }
    $changes
}

TEST { hash_diff {a => 1, b => 2}, {a => 1, b => 3} }
+{'a' => 'unchanged', 'b' => 'changed'};
TEST { hash_diff {a => 1, b => 2}, {a => 1, b => 3, c => 5} }
+{'c' => 'added', 'a' => 'unchanged', 'b' => 'changed'};
TEST { hash_diff {a => 1, b => 2}, {b => 3, c => 5} }
+{'c' => 'added', 'a' => 'deleted', 'b' => 'changed'};
TEST {
    hash_diff {a => 1, b => 2, x => 9},
        {a => undef, b => 3, c => 5, x => 9}
}
+{'c' => 'added', 'a' => 'deleted', 'b' => 'changed', 'x' => 'unchanged'};

sub subhash {
    my $s = shift;
    my %r;
    for (@_) {
        $r{$_} = $$s{$_}
    }
    \%r
}

TEST { subhash({a => 10, b => 11, c => 12}, "a", "c") }
+{a => 10, c => 12};

use FP::HashSet;

sub hashes_keys {
    keys %{array_to_hashset([map { keys %$_ } @_])}
}

# set leafs in 2-level hash structure:
sub hash2_set ($$$$) {
    my ($h, $k0, $k1, $v) = @_;
    hash_update $h, $k0, sub { my ($h1) = @_; hash_set $h1, $k1, $v }
}

1
