#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Equal - generic equality comparison

=head1 SYNOPSIS

    use FP::Equal;
    use FP::List;
    use FP::Div qw(inc);

    ok equal [1, list(2, 3)], [1, list(1, 2)->map(*inc)];
    is equal( [1, list(2, 3)], [1, list(1, 2)] ),
       ''; # false but defined since same type
    is equal( [1, list(2, 3)], [1, list([], 3)] ),
       undef; # to say it's not the same type

    # equal forces any promises that it encounters:
    use FP::Lazy; use FP::List 'pair';
    ok equal lazy{pair 3, lazy{2 + 1}},
             pair(3, 2 + 1);

    use FP::Stream 'string_to_stream';
    is equal( string_to_stream("Hello"),
              string_to_stream("Hello1") ),
       undef; # not the same type at the end, null vs. pair;
              # although this may be subject to change

    # n-ary variant of equal (not done in equal itself for performance
    # reasons and to allow for prototype declaration):
    use FP::Equal qw(equaln);
    is equaln("a", "a", "a"), 1;
    is equaln("a", "a", "b"), '';

    # For writing tests with Test::More--the same as `is` but uses
    # `equal` for comparisons, and shows values in failures via
    # `show`:
    use FP::Equal qw(is_equal);
    is_equal list(1+1), list(2);

    # `equal` is giving an exception if 2 objects of the (~)same class
    # are given, but the class doesn't implement the protocol:
    is_equal [ scalar eval {
                  equal bless([1+1], 'FP::Equal::EXAMPLE'),
                        bless([2], 'FP::Equal::EXAMPLE')
               },
               length("$@")>5 ],
             [undef, 1];

    # `relaxedequal` does not throw exceptions, it falls back to
    # FP::DumperEqual if a class doesn't implement the protocol:
    use FP::Equal qw(relaxedequal);
    is_equal [ scalar eval {
                  relaxedequal
                        bless([1+1], 'FP::Equal::EXAMPLE'),
                        bless([2], 'FP::Equal::EXAMPLE')
               },
               length("$@") ],
             [1, 0];

=head1 DESCRIPTION

Deep, generic (class controlled) structure equality comparison.

Non-objects are hard coded in this module. Objects are expected to
have an `FP_Equal_equal` method that is able to take an argument of
the same class as the object to compare. If it doesn't have such an
object, it simply can't be compared using the C<equal*> functions,
they will give "no such method" exceptions; C<relaxedequal> falls back
to using L<FP::DumperEqual> (which uses L<Data::Dumper>) in such
cases.

This does *name based* type comparison: structurally equivalent
objects do not count as equal if they do not have the same class (or
more general, reference name); the `FP_Equal_equal` method is not even
called in this case, and the functions return undef. This might be
subject to change: certain pairs of types will be fine to compare; let
the classes provide a method that checks whether a type is ok to
compare?

=head1 TODO

- cycle detection

- immutable version -> equals_now equals_forever

- do we need the possibility for "context" dependent (and not by way
  of subclassing and overriding equals_*) equality comparisons?

=head1 SEE ALSO

L<FP::Abstract::Equal> for the protocol definition

L<FP::DumperEqual> used as fallback in C<relaxedequal>.

L<FP::Show>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Equal;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(equal);
our @EXPORT_OK   = qw(equaln is_equal relaxedequal pointer_eq);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

# equal can easily recurse deeply into data structures.
no warnings "recursion";

# To be fair, it's also currently missing loop detection, TODO.

# I find it odd that nobody did this before. But I can't find anything
# on CPAN.

our $primitive_equals = +{
    ARRAY => sub {
        my ($a, $b, $equal) = @_;
        @$a == @$b and do {
            my $i = 0;
        LP: {
                $i < @$a
                    ? (
                    &$equal($$a[$i], $$b[$i])
                        and do { $i++; redo LP }
                    )
                    : 1
            }
        }
    },
    HASH => sub {
        my ($a, $b, $equal) = @_;
        keys %$a == keys %$b and do {
            for (keys %$a) {
                my $v;
                $v = (exists $$b{$_} and &$equal($$a{$_}, $$b{$_}))
                    or return $v;
            }
            1
        }
    },
    REF => sub {    # references to references
        my ($a, $b, $equal) = @_;
        &$equal($$a, $$b)
    },

    # *references* to globs; direct globs are compared in equal directly
    GLOB => sub {

        # is it the same glob? If it's different ones, compare all of
        # their contents? XX if so, then also change the direct
        # comparison in equal
        ''      # since if they are the same, then pointer comparison
                # already did it
    },
    SCALAR => sub {
        my ($a, $b, $equal) = @_;
        &$equal(${ $_[0] }, ${ $_[1] })
    },

    # compare closures using XS? Existing module?
    #CODE => sub {
    #}
};

use Scalar::Util qw(refaddr blessed);
use FP::Lazy;

sub pointer_eq ($$) {
    my $a = refaddr($_[0]) // return;
    my $b = refaddr($_[1]) // return;
    $a == $b
}

sub make_equal {
    my ($relaxed) = @_;
    my $equal;
    $equal = sub ($$) {
        @_ == 2 or die "wrong number of arguments";
    EQUAL: {
            my ($a, $b) = @_;
            if (!defined $a) {
                if (!defined $b) {
                    1
                } else {
                    if (length ref $b) {
                        if (is_promise $b) {
                            @_ = ($a, force($b));
                            redo EQUAL;
                        } else {
                            undef
                        }
                    } else {
                        undef
                    }
                }
            } else {

                # $a is defined
                if (!defined $b) {
                    if (length ref $a) {
                        if (is_promise $a) {
                            @_ = (force($a), $b);
                            redo EQUAL;
                        } else {
                            undef
                        }
                    } else {
                        undef
                    }
                } else {

                    # both are defined
                    if (length(my $ar = ref $a)) {
                        if (length(my $br = ref $b)) {
                            pointer_eq($a, $b) or do {
                                if (is_promise $a or is_promise $b) {
                                    @_ = (force($a), force($b));
                                    redo EQUAL;
                                } elsif ($ar eq $br) {
                                    if (my $cmp = $$primitive_equals{$ar}) {
                                        &$cmp($a, $b, $equal)
                                    } else {
                                        if ($relaxed) {
                                            if (defined blessed($a)
                                                and my $m
                                                = $a->can("FP_Equal_equal"))
                                            {
                                  #@_ $a and $b are still the original $a and $b
                                                goto $m
                                            } else {

                                             # costly require?, but slow anyway.
                                                require FP::DumperEqual;

                                                # and, given that slow
                                                # anyway, take the
                                                # safe path via
                                                # Useperl (_utf8
                                                # variant)
                                                FP::DumperEqual::dumperequal_utf8(
                                                    $a, $b)
                                            }
                                        } else {
                                            $a->FP_Equal_equal($b)
                                        }
                                    }
                                } else {

                                    # XXX allow subclasses of same
                                    # hierarchy? Check whether $br isa $ar
                                    # or vica versa and then call
                                    # FP_Equal_equal on the one that's more?
                                    # (or the less?) specialized?
                                    undef
                                }
                            };
                        } else {

                            # $b is not a reference ($a is)
                            if (is_promise $a) {
                                @_ = (force($a), $b);
                                redo EQUAL;
                            } else {
                                undef
                            }
                        }
                    } else {

                        # $a is not a reference
                        if (length ref $b) {
                            if (is_promise $b) {
                                @_ = ($a, force($b));
                                redo EQUAL;
                            } else {
                                undef
                            }
                        } else {

                         # $b is not a reference either
                         # make sure it's the same kind of non-reference values:
                            if (ref(\$a) eq ref(\$b)) {

                       # XX number comparison could optimize the case where both
                       # values don't have string representations, compare using
                       # == then.

                        # XXX Also, on a slightly independent note, and not just
                        # an optimization: in the other case (any of the
                        # arguments also has a string representation) compare
                        # both as string and as number?

                                $a eq $b
                            } else {
                                undef
                            }
                        }
                    }
                }
            }
        }
    }
}

sub equal($$);
*equal = make_equal(0);
sub relaxedequal($$);
*relaxedequal = make_equal(1);

sub equaln {
    if (@_ == 2) {
        goto \&equal
    } elsif (@_ == 1) {
        1
    } else {
        my $a = shift;
        for (@_) {
            my $v;
            $v = equal($a, $_) or return $v;
        }
        1
    }
}

sub is_equal ($$;$) {
    my ($a, $b, $maybe_name) = @_;
    require Test::More;
    my $tb = Test::More->builder;

    if (equal $a, $b) {
        $tb->ok(1, $maybe_name ? $maybe_name : ())
    } else {
        require FP::Show;
        $tb->is_eq(FP::Show::show($a), FP::Show::show($b),
            $maybe_name ? $maybe_name : ())
    }
}

1
