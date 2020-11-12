#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Trie - purely functional prefix tree

=head1 SYNOPSIS

    use FP::Trie;

    my $t = empty_trie->set(string_to_list ("Hello"), "World");
    $t->perhaps_ref(string_to_list("Hell")); # ()
    if (my ($subt) = $t->perhaps_skip(string_to_list("Hell"))) {
        print $subt->sublevels_length;
        if (my ($v) = $subt->perhaps_ref(string_to_list("o"))) {
            print $v;
        }
    }
    # -> prints "1World"

    $t->maybe_ref ($keylist)
    $t->ref ($keylist)
    $t->ref_or ($keylist, $alternativevalue)
    $t->exists ($keylist) # boolean

    $t->xdelete(string_to_list("Hello"))
      ->delete(string_to_list("Hello"))  # silently does not change anything;
      ->xdelete(string_to_list("Hello")) # throws "key not found" exception

    $t->keys   # stream of keys
    $t->values # stream of values
    $t->alist  # stream of [ key, value ]

    $t->update($keylist, $fn) # $fn receives () if no such value is in
                              # the trie; if it returns (), the entry
                              # will be deleted


=head1 DESCRIPTION

The trie operations expect an efficiently dissectable sequence (linked
list, stream) as the key. Each item denotes the next level in the
nested trie levels. The items in the list can be anything with a
sensible stringification. To use FP::Trie for string keys, turn the
strings to character lists using `string_to_list`.

`perhaps_skip` returns the remainder of the trie with the given prefix
skipped (again a trie, if available).

`skip` returns ($ending_level, $maybe_keyremainder,
$maybe_lastvaluelevel, $maybe_keyremainder_lvl), where
$maybe_keyremainder is the remainder of the key list after the last
matching level, $ending_level is that level, and $maybe_lastvaluelevel
is the last level holding a value and $maybe_keyremainder_lvl the
remainder of the key at that point.

=head1 PERFORMANCE

Update performance is bad because we don't have an efficiently
updatable pure (hash) table datastructure yet.

=head1 NAMES

Are the method names ok? What names are other common implementations
using? (todo: check Hoogle etc.)

=head1 SEE ALSO
 
Implements: L<FP::Abstract::Show>, L<FP::Abstract::Pure>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Trie;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw(empty_trie);
@EXPORT_OK   = qw($empty_trie);                  # ok?
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

{

    package FP::Trie::KeyNotFoundException;
    use FP::Struct [], 'FP::Struct::Show', 'FP::Abstract::Pure';
    use overload '""' => 'string';
    sub string {"key not found"}
    _END_
}

{

    package FP::Trie::Trie;
    use FP::Struct [], 'FP::Struct::Show', 'FP::Abstract::Pure';
    _END_
}

{

    package FP::Trie::BareLevel;

    use FP::Hash ':all';
    use FP::Optional qw(perhaps_to_maybe perhaps_to_x
        perhaps_to_or perhaps_to_exists);
    use FP::Lazy;
    use FP::List;
    use FP::Stream;

    use FP::Struct ["sublevels"], "FP::Trie::Trie";

    sub perhaps_value { () }

    sub perhaps_skip {
        @_ == 2 or die "wrong number of arguments";
        my ($t,  $l)        = @_;
        my ($t2, $maybe_l2) = $t->skip($l);
        defined $maybe_l2 ? () : ($t2)
    }

    our $key_not_found_exception = new FP::Trie::KeyNotFoundException;

    sub perhaps_ref {
        @_ == 2 or die "wrong number of arguments";
        my ($t, $l) = @_;
        if (my ($t2) = $t->perhaps_skip($l)) {
            $t2->perhaps_value
        } else { () }
    }
    *maybe_ref = perhaps_to_maybe * perhaps_ref;
    *ref_or    = perhaps_to_or * perhaps_ref;
    *ref       = perhaps_to_x * perhaps_ref, $key_not_found_exception;
    *exists    = perhaps_to_exists * perhaps_ref;

    # returns ($ending_level, $maybe_keyremainder,
    # $maybe_lastvaluelevel, $maybe_keyremainder_lvl)
    sub skip {
        @_ == 2 or @_ == 4 or die "wrong number of arguments";
        my ($t, $l, $maybe_lastvaluelevel, $maybe_keyremainder_lvl) = @_;
        my ($maybe_lvl, $maybe_r_lvl)
            = UNIVERSAL::isa($t, "FP::Trie::ValueLevel")
            ? ($t, $l)
            : ($maybe_lastvaluelevel, $maybe_keyremainder_lvl);
        if ($l->is_null) {

            # found the node, which is perhaps holding a value
            ($t, undef, $maybe_lvl, $maybe_r_lvl)
        } else {
            my ($a, $l2) = $l->first_and_rest;
            if (my ($t2) = hash_perhaps_ref($$t{sublevels}, $a)) {

                # XX TCO
                $t2->skip($l2, $maybe_lvl, $maybe_r_lvl)
            } else {

                # no value for the full key; $t is the last seen
                # level, $l the remainder of the key
                ($t, $l, $maybe_lvl, $maybe_r_lvl)
            }
        }
    }

    sub update {
        @_ == 3 or die "wrong number of arguments";
        my ($t, $l, $fn) = @_;
        if ($l->is_null) {
            FP::Trie::ValueLevel->new($$t{sublevels}, &$fn($t->perhaps_value))
        } else {
            my ($a, $l2) = $l->first_and_rest;
            $t->sublevels_update(sub {
                hash_update $_[0], $a, sub {
                    do {
                        if (my ($t2) = @_) {
                            $t2
                        } else {
                            $FP::Trie::empty_trie
                        }
                        }
                        ->update($l2, $fn)
                }
            })
        }
    }

    sub xdelete {
        @_ == 2 or die "wrong number of arguments";
        my ($t, $l) = @_;
        if ($l->is_null) {
            if (UNIVERSAL::isa($t, "FP::Trie::ValueLevel")) {
                if (keys %{ $$t{sublevels} }) {
                    FP::Trie::BareLevel->new($$t{sublevels})
                } else {

                    # equivalent but detectable to be empty from outer
                    # layers
                    $FP::Trie::empty_trie
                }
            } else {
                die $key_not_found_exception
            }
        } else {
            my ($a, $l2) = $l->first_and_rest;
            $t->sublevels_update(sub {
                hash_update $_[0], $a, sub {
                    if (my ($t2) = @_) {
                        my $t3 = $t2->xdelete($l2);
                        $t3 eq $FP::Trie::empty_trie ? () : $t3
                    } else {

                        #()
                        # When does this happen? When the key goes
                        # past the existing tree.
                        die $key_not_found_exception
                    }
                }
            })
        }
    }

    sub delete {
        @_ == 2 or die "wrong number of arguments";
        my ($t, $l) = @_;

        # This is really calling for call/cc (parametrize the end case
        # in xdelete, with either a continuation call or the call to
        # an exception handler). But we have what we have (for now).
        my $res;
        if (eval {
            $res = $t->xdelete($l);
            1
        })
        {
            $res
        } else {
            my $e = $@;
            if (ref $e and UNIVERSAL::isa($e, "FP::Trie::KeyNotFoundException"))
            {
                $t
            } else {
                die $e
            }
        }
    }

    sub set {
        @_ == 3 or die "wrong number of arguments";
        my ($t, $l, $v) = @_;
        $t->update($l, sub {$v})
    }

    sub sublevels_length {
        @_ == 1 or die "wrong number of arguments";
        my ($t) = @_;
        hash_length $t->sublevels
    }

    # key_and_value_s, association list
    sub alist {
        my ($t, $maybe_rprefix, $maybe_tail) = @_;
        my $rprefix = $maybe_rprefix // null;
        if (0) {

            # XXX Why the hell does this not work, while the non-OO
            # variant does?
            stream(keys %{ $$t{sublevels} })->fold_right(
                sub {
                    my ($k, $rest) = @_;
                    $$t{sublevels}{$k}->alist(cons($k, $rprefix), $rest)
                },
                $maybe_tail // null
            );
        } else {
            stream_fold_right(
                sub {
                    my ($k, $rest) = @_;
                    $$t{sublevels}{$k}->alist(cons($k, $rprefix), $rest)
                },
                $maybe_tail // null,
                stream keys %{ $$t{sublevels} }
            );
        }
    }

    sub keys {
        @_ == 1 or die "wrong number of arguments";
        my ($t) = @_;
        $t->alist->stream_map(sub { $_[0][0] })
    }

    # XX usually I'm using `values` to return a Perl "list"! But what
    # else should this be named? `valuestream`? And the above
    # `keystream`?
    sub values {
        @_ == 1 or die "wrong number of arguments";
        my ($t) = @_;
        $t->alist->stream_map(sub { $_[0][1] })
    }

    # Turn trie to a nested list representation, for debugging or
    # interoperation; call `write_sexpr` on it to get a readable
    # printout.
    sub sexpr {
        my ($t) = @_;
        my $sublevels = $t->sublevels;
        cons(
            list($t->perhaps_value),
            list(
                map { list($_, $$sublevels{$_}->sexpr) }
                sort (CORE::keys %$sublevels)
            )
        )
    }

    _END_
}

{

    package FP::Trie::ValueLevel;

    use FP::List;
    use FP::Lazy;

    use FP::Struct ["value"], "FP::Trie::BareLevel";

    sub perhaps_value {
        my ($t) = @_;
        $$t{value}
    }

    sub alist {
        my ($t, $maybe_rprefix, $maybe_tail) = @_;
        my $rprefix = $maybe_rprefix // null;
        lazy {
            cons(
                [$rprefix->reverse, $$t{value}],
                $t->SUPER::alist($rprefix, $maybe_tail)
            )
        }
    }

    _END_
}

our $empty_trie = FP::Trie::BareLevel->new({});

sub empty_trie {
    $empty_trie
}

1
