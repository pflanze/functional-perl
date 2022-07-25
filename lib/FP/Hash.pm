#
# Copyright (c) 2014-2022 Christian Jaeger, copying@christianjaeger.ch
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

    # Curried hash lookup:
    is_equal hashkey("foo")->({foo=> 10, bar=> 20}), 10;
    use FP::Array_sort qw(array_sort on);
    use FP::Ops qw(real_cmp);
    is_equal array_sort([ {a=> 3, b=> "a"}, {a=> 2, b=> "b"} ],
                        on hashkey("a"), \&real_cmp),
             [ {a=> 2, b=> "b"}, {a=> 3, b=> "a"} ];

    is_equal hash_map({a=> 1, b=> 2, c=> 33, d=> 4},
                      sub {
                          my ($k, $v)= @_;
                          $v > 10 ? () : (uc $k, $v*2)
                      }),
             {A=> 2, B=> 4, D=> 8};
    is_equal hash_filter({a=> 1, b=> 2, c=> 33, d=> 4},
                      sub {
                          my ($k, $v)= @_;
                          $v >= 2 and $k < 'd'
                      }),
             {b=> 2, c=> 33};
    is_equal hash_key_filter({a=> 1, b=> 2, c=> 33, d=> 4},
                      sub {
                          my ($k)= @_;
                          $k < 'b'
                      }),
             {a=> 1};
    is_equal hash_value_filter({a=> 1, b=> 2, c=> 33, d=> 4},
                      sub {
                          my ($v)= @_;
                          $v <= 4
                      }),
             {a=> 1, b=> 2};

    # NOTE: `mesh` might be added to List::Util, too
    is_equal +{ mesh [qw(a b c)], [2,3,4] },
            { a=> 2, b=> 3, c=> 4 };
    is_equal ziphash([qw(a b c)], [2,3,4]),
            { a=> 2, b=> 3, c=> 4 };

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
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(hash_set hash_perhaps_ref hash_maybe_ref hash_xref
    hash_ref_or hashkey mesh ziphash hash_cache hash_delete
    hash_update hash_diff hash_length subhash hashes_keys $empty_hash
    hash_map hash_filter hash_key_filter hash_value_filter
    hash2_set );
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;
use Chj::TEST;
use FP::Carp;

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

sub hash_set {
    @_ == 3 or fp_croak_arity 3;
    my ($h, $k, $v) = @_;
    my $h2 = +{%$h};
    $$h2{$k} = $v;
    $h2
}

my $h = { a => 1, b => 2 };
TEST { hash_set $h, b => 3 }
+{ 'a' => 1, 'b' => 3 };
TEST {$h}
+{ 'a' => 1, 'b' => 2 };

sub hash_delete {
    @_ == 2 or fp_croak_arity 2;
    my ($h, $k) = @_;
    my $h2 = +{%$h};
    delete $$h2{$k};
    $h2
}

sub hash_update {
    @_ == 3 or fp_croak_arity 3;
    my ($h, $k, $fn) = @_;
    my $h2 = +{%$h};
    if (my ($v) = &$fn(exists $$h{$k} ? $$h{$k} : ())) {
        $$h2{$k} = $v;
    } else {
        delete $$h2{$k}
    }
    $h2
}

TEST {
    hash_update $h, 'a', sub { $_[0] + 10 }
}
+{ a => 11, b => 2 };
TEST {
    hash_update $h, 'x', sub { [@_] }
}
+{ a => 1, b => 2, x => [] };
TEST {
    hash_update $h, 'a', sub { () }
}
+{ b => 2 };

sub hash_length {
    @_ == 1 or fp_croak_arity 1;
    my ($h) = @_;
    scalar keys %$h
}

TEST { hash_length +{} } 0;
TEST { hash_length +{ a => 4, b => 5 } } 2;

sub hash_perhaps_ref {
    @_ == 2 or fp_croak_arity 2;
    my ($h, $k) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    } else {
        ()
    }
}

# difference of the following to just $$h{$k} is that it won't die on
# locked hashes
sub hash_maybe_ref {
    @_ == 2 or fp_croak_arity 2;
    my ($h, $k) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    } else {
        undef
    }
}

sub hash_xref {
    @_ == 2 or fp_croak_arity 2;
    my ($h, $k) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    } else {
        die "unbound table key";    # no such key. unknown key. unbound
                                    # hash key. ?
    }
}

sub hash_ref_or {
    @_ == 3 or fp_croak_arity 3;
    my ($h, $k, $other) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    } else {
        $other
    }
}

# Curried hash lookup
sub hashkey {
    @_ == 1 or fp_croak_arity 1;
    my ($key) = @_;
    sub {
        @_ == 1 or fp_croak_arity 1;
        my ($h) = @_;
        $h->{$key}
    }
}

sub mesh {
    @_ == 2 or fp_croak_arity 2;
    my ($keys, $values) = @_;
    map { $keys->[$_] => $values->[$_] } 0 .. $#$keys
}

sub ziphash {
    @_ == 2 or fp_croak_arity 2;
    my ($keys, $values) = @_;
    +{ map { $keys->[$_] => $values->[$_] } 0 .. $#$keys }
}

sub hash_cache {

    @_ == 3 or fp_croak_arity 3;

# only allowing for scalar context
    my ($h, $k, $generate) = @_;
    if (exists $$h{$k}) {
        $$h{$k}
    } else {
        $$h{$k} = &$generate()
    }
}

# looking for definedness, not exists. Ok? Also, only handles strings
# as values.
sub hash_diff {
    @_ == 2 or fp_croak_arity 2;
    my ($h1, $h2) = @_;
    my $changes = {};
    for my $key (keys %$h2) {
        my $old = $$h1{$key};
        my $new = $$h2{$key};
        if (defined($old) and defined($new)) {
            $$changes{$key} = ($old eq $new) ? "unchanged" : "changed";
        } else {
            $$changes{$key} = defined($old) ? "deleted" : "added";
        }
    }
    for my $key (keys %$h1) {
        next if defined $$h2{$key};
        $$changes{$key} = "deleted";
    }
    $changes
}

TEST { hash_diff { a => 1, b => 2 }, { a => 1, b => 3 } }
+{ 'a' => 'unchanged', 'b' => 'changed' };
TEST { hash_diff { a => 1, b => 2 }, { a => 1, b => 3, c => 5 } }
+{ 'c' => 'added', 'a' => 'unchanged', 'b' => 'changed' };
TEST { hash_diff { a => 1, b => 2 }, { b => 3, c => 5 } }
+{ 'c' => 'added', 'a' => 'deleted', 'b' => 'changed' };
TEST {
    hash_diff { a => 1, b => 2, x => 9 },
        { a => undef, b => 3, c => 5, x => 9 }
}
+{ 'c' => 'added', 'a' => 'deleted', 'b' => 'changed', 'x' => 'unchanged' };

sub subhash {
    my $s = shift;
    my %r;
    for (@_) {
        $r{$_} = $$s{$_}
    }
    \%r
}

TEST { subhash({ a => 10, b => 11, c => 12 }, "a", "c") }
+{ a => 10, c => 12 };

use FP::HashSet;

sub hashes_keys {
    keys %{ array_to_hashset([map { keys %$_ } @_]) }
}

sub hash_map {
    @_ == 2 or fp_croak_arity 2;
    my ($h, $fn) = @_;
    +{ map { $fn->($_, $$h{$_}) } keys %$h }
}

sub hash_filter {
    __ 'only keep k=>v entries for which $pred->($k, $v) is true';
    @_ == 2 or fp_croak_arity 2;
    my ($hash, $pred) = @_;
    +{
        map {
            my $v = $hash->{$_};
            $pred->($_, $v) ? ($_ => $v) : ()
        } keys %$hash
    }
}

sub hash_key_filter {
    __ 'only keep k=>v entries for which $pred->($k) is true';
    @_ == 2 or fp_croak_arity 2;
    my ($hash, $pred) = @_;
    +{ map { $pred->($_) ? ($_ => $hash->{$_}) : () } keys %$hash }
}

sub hash_value_filter {
    __ 'only keep k=>v entries for which $pred->($v) is true';
    @_ == 2 or fp_croak_arity 2;
    my ($hash, $pred) = @_;
    +{
        map {
            my $v = $hash->{$_};
            $pred->($v) ? ($_ => $v) : ()
        } keys %$hash
    }
}

# set leafs in 2-level hash structure:
sub hash2_set {
    @_ == 4 or fp_croak_arity 4;
    my ($h, $k0, $k1, $v) = @_;
    hash_update $h, $k0, sub { my ($h1) = @_; hash_set $h1, $k1, $v }
}

1
