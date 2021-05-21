#
# Copyright (c) 2013-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Lazy - lazy evaluation (delayed evaluation, promises)

=head1 SYNOPSIS

    use FP::Lazy;

    my $a = lazy { 1 / 0 };
    eval {
        print force $a
    };
    like $@, qr/^Illegal division by zero/;

    eval {
        $a + 2
    };
    like $@, qr/^non-auto-forcing promise accessed via 0\+ operation/;

    my $count = 0;
    my $b = lazy { $count++; 1 / 2 };
    is is_promise($b), 1;
    is $count, 0;
    is force($b), 1/2; # increments $count
    is $count, 1;
    # $b is still a promise at this point (although an evaluated one):
    is is_promise($b), 1;
    is force($b), 1/2; # does not increment $count anymore
    is $count, 1;

    # The following stores result of `force $b` back into $b
    FORCE $b;
    is is_promise($b), undef;
    is $b, 1/2;
    is $count, 1;

    # Note that lazy evaluation and mutation usually doesn't mix well -
    # lazy programs better be purely functional. Here $tot depends not
    # just on the inputs, but also on how many elements were evaluated:
    use FP::Stream qw(stream_map); # uses `lazy` internally
    use FP::List;
    {
        my $tot = 0;
        my $l = stream_map sub {
            my ($x) = @_;
            $tot += $x;
            $x*$x
        }, list (5,7,8);
        is $tot, 0;
        is $l->first, 25;
        is $tot, 5;
        is $l->length, 3;
        is $tot, 20;
    }

    # Also note that `local` does mutation (even if in a somewhat
    # controlled way):
    our $foo = "";
    sub moo {
        my ($bar) = @_;
        local $foo = "Hello";
        lazy { "$foo $bar" }
    }
    is moo("you")->force, " you";

    # runtime conditional lazyness:

    sub condprom {
        my ($cond) = @_;
        lazy_if { 1 / 0 } $cond
    }

    ok is_promise(condprom 1);

    eval {
        # immediate division by zero exception (still pays
        # the overhead of two subroutine calls, though)
        condprom 0
    };
    like $@, qr/^Illegal division by zero/;

    # Calling methods on those promises will automatically force them,
    # which is normally necessary since there's no way to know the
    # class of the object otherwise:
    use FP::Lazy qw(is_forced);
    {
        my $l = lazy { cons(1, null) };
        ok !is_forced($l);
        my $l2 = $l->cons(10);
        # $l was forced even though the only reason is to know which
        # class to call `cons` on:
        ok is_forced($l);
    }

    # There's `lazyT` which specifies the (or a base) class of the
    # object statically, hence there's no need to evaluate a promise
    # just to call a method. In this case the called method receives
    # the unevaluated promise as its argument! (This might change in
    # that either some flag in the the interface definition, or simply
    # the stream_ prefix of a method could be required, otherwise it
    # would still be forced. That would make it safe(r) but *maybe*
    # (given a good test suite) it's not necessary?)
    {
        my $l = lazyT { cons(1, null) } "FP::List::Pair";
        ok !is_forced($l);
        my $l2 = $l->cons(10);
        # $l has *not* been forced now.
        ok !is_forced($l);
    }

    # And `lazyT_if` which is the conditional variant:
    sub typed_condprom {
        my ($cond) = @_;
        lazyT_if { list(1 / 0) } "FP::List::List", $cond
    }
    ok is_promise(typed_condprom 1);
    eval {
        # immediate division by zero exception (still pays
        # the overhead of two subroutine calls, though)
        typed_condprom 0
    };
    like $@, qr/^Illegal division by zero/;

    # A `lazyLight` promise is re-evaluated on every access:
    my $z = 0;
    my $v = lazyLight { $z++; 3*4 };
    is force($v), 12;
    is $z, 1;
    is force($v), 12;
    is $z, 2;

    # There are 3 possible motivations for lazyLight: (1) lower
    # allocation cost (save the wrapper data structure); (2) no risk
    # for circular references (due to storing the result back into the
    # wrapper (mutation) that can be used recursively); (3) to get
    # fresh re-evaluation on every access and thus picking up any
    # potential side effect.

    # Arguably (3) is against the functional programming idea, and is
    # a bit of a mis-use of lazyLight. For now, FP::TransparentLazy
    # still helps this case by not using `FORCE` automatically. (TODO:
    # provide another type that provides this with a guarantee?)

    # Note that manual use of `FORCE` still stops the re-evalution:

    ok ref $v;
    is FORCE($v), 12;
    is $z, 3;
    is force($v), 12;
    is $z, 3; # you can see that re-evaluation has stopped
    ok not ref $v;

=head1 DESCRIPTION

This implements promises, a data type that represents an unevaluated
or evaluated computation. The computation represented by a promise is
only ever evaluated once, after which point its result is saved in the
promise, and subsequent requests for evaluation are simply returning
the saved value.

    my $p = lazy { "......" }; # returns a promise that represents the computation
                               # given in the block of code

    force $p;  # runs the block of code and stores the result within the
               # promise and also returns it

    FORCE $p; # or FORCE $p,$q,$r;
              # in addition to running force, stores back the resulting
              # value into the variable given as argument ($p, $q, and $r
              # respectively (the commented example forces 3 (possibly)
              # separate values))

    is is_promise($p), undef; # returns true iff $x holds a promise


=head1 NOTE

The thunk (code body) of a promise is always evaluated in scalar
context, even if it is being forced in list or void context.

=head1 NAMING

The name `lazy` for the delaying form was chosen because it seems what
most frameworks for functional programming on non-functional
programming languages are using, as well as Ocaml. We don't want to
stand in the way of what people expect, after all.

Scheme calls the lazy evaluation form `delay`. This seems to make
sense, as that's a verb, unlike `lazy`. There's a conceptually
different way to introduce lazyness, which is to change the language
to be lazy by default, and `lazy` could be misunderstood to be a form
that changes the language in its scope to be that. Both for this
current (slight?) risk for misinterpretation, and to reserve it for
possible future implementation of this latter feature, it seems to be
wise to use `delay` and not `lazy` for what this module offers.

What should we do?

(To experiment with the style, or in case you're stubborn, you can
explicitely import `delay` or import the `:all` export tag to get it.)

=head1 TODO

If the thunk of a promise throws an exception, the promise will remain
unevaluated. This is the easiest (and most efficient) thing to do, but
there remains a question about the safety: if the data source is
read-once (like reading lines from files), and the exception happens
after the read, then forcing the promise again will fetch and store
the next line, hence a line will be lost. Since exceptions can happen
because of out of memory conditions or from signal handlers, this will
be of real concern in some situations.

Provide safe promises for these situations? (But that would mean that
they need to be implemented in C as Perl does not offer the features
to implement them safely, correct?)

=head1 DEBUGGING

Lazy code can be difficult to debug because the context in which the
code that evaluates a promise runs is not the same context in which
the promise was captured. There are two approaches to make this
easier:

C<$ENV{DEBUG_FP_LAZY} = "1"> or C<local $FP::Lazy::debug=1> -- captures
a backtrace in every promise (slow, of course!). Use the optionally
exported C<lazy_backtrace> function to get the backtrace (or look at
it via the repl's :d (Data::Dumper) mode).

C<$ENV{DEBUG_FP_LAZY} = "eager"> or C<local $FP::Lazy::eager=1> --
completely turns of any lazyness (except for lazyLight, currently);
easy stack traces and flow logic but of course the program behaves
differently; beware of infinite lists!


=head1 SEE ALSO

https://en.wikipedia.org/wiki/Futures_and_promises

Alternative Data::Thunk, but see note in TODO file about problems.

Alternative Scalar::Defer?

L<FP::TransparentLazy>

L<FP::Mixin::Utils> -- Lazy implements this as a fallback (lower
priority than forcing the promise and finding the method on the
result)

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Lazy;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(lazy lazyT lazy_if lazyT_if lazyLight force FORCE is_promise);
our @EXPORT_OK   = qw(delay force_noeval lazy_backtrace is_forced);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Carp;
use FP::Carp;
use FP::Mixin::Utils;
use FP::Show;
use Scalar::Util 'blessed';
use FP::Docstring;

our $eager = ($ENV{DEBUG_FP_LAZY} and $ENV{DEBUG_FP_LAZY} =~ /^eager$/i);
our $debug = $ENV{DEBUG_FP_LAZY} ? (not $eager) : '';

sub die_not_a_Lazy_Promise {
    my ($v) = @_;
    die "not a FP::Lazy::Promise: " . show($v);
}

# A promise is an array with two fields:
# index 0: thunk when unevaluated, undef once evaluated
# index 1: value once evaluated
# index 2: maybe blessed(force($promise))
# index 3: backtrace if $debug is true

sub is_forced {
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;

    # Note that $v might not even be a promise (anymore), given FORCE
    # and AUTOLOAD.

    my $m;
    blessed($v) ? (($m = $v->can("FP_Lazy_is_forced")) ? &$m($v) : 1) : 1
}

sub lazy_backtrace {    # not a method to avoid shadowing any
                        # 'contained' method
    @_ == 1 or fp_croak_arity 1;
    my ($v) = @_;
    blessed($v) // die_not_a_Lazy_Promise($v);

    # Consciously not working for Light ones!
    if ($v->isa("FP::Lazy::AnyPromise")) {
        $$v[3]          # really assume such an access works, no fallback to a
                        # method like in FP::List
    } else {
        die_not_a_Lazy_Promise($v);
    }
}

sub lazy (&) {
    __ '`lazy { expr }`: evaluate expr only when forced via `force`';
    $eager ? goto $_[0]
        : $debug
        ? bless([$_[0], undef, undef, FP::Repl::Stack->get(1)->backtrace],
        "FP::Lazy::Promise")
        : bless([$_[0], undef], "FP::Lazy::Promise")
}

sub lazyT (&$) {
    __ '`lazyT { expr } $classname`: expr must return an object that
        satisfies ->isa($classname)';
    $eager ? goto $_[0] : bless [
        $_[0], undef,
        $_[1], $debug ? FP::Repl::Stack->get(1)->backtrace : ()
        ],
        "FP::Lazy::Promise"
}

sub lazy_if (&$) {
    __ '`lazy_if { expr } $boolean`: evaluate expr immediately if
       $boolean is false, lazily otherwise';
    (
        ($_[1] and not $eager)
        ? (
            $debug
            ? bless([$_[0], undef, undef, FP::Repl::Stack->get(1)->backtrace],
                "FP::Lazy::Promise")
            : bless([$_[0], undef], "FP::Lazy::Promise")
            )
        : do {
            my ($thunk) = @_;
            @_ = ();
            goto $thunk;
        }
    )
}

sub lazyT_if (&$$) {
    __ '`lazyT_if { expr } $classname, $boolean`: expr must return an
        object that satisfies ->isa($classname); eager unless $boolean
        is true.';
    (
        ($_[2] and not $eager)
        ? (
            bless [
                $_[0], undef,
                $_[1], $debug ? FP::Repl::Stack->get(1)->backtrace : ()
            ],
            "FP::Lazy::Promise"
            )
        : goto $_[0]
    )
}

# not providing for caching (1-time-only evaluation)
sub lazyLight (&) {
    $eager ? goto $_[0] : bless $_[0], "FP::Lazy::PromiseLight"
}

sub is_promise {
    @_ == 1 or fp_croak_arity 1;
    blessed($_[0]) // return;
    $_[0]->isa("FP::Lazy::AnyPromise")
}

sub delay (&);
*delay = \&lazy;
sub delayLight (&);
*delayLight = \&lazyLight;

sub die_type_error {
    my ($expected, $gotstr, $v) = @_;
    die "promise expected to evaluate to an object "
        . "of class '$expected' but got $gotstr: "
        . show($v)
}

sub force {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($perhaps_promise, $nocache) = @_;
LP: {
        if (defined blessed($perhaps_promise)) {
            if ($perhaps_promise->isa("FP::Lazy::PromiseLightBase")) {
                $perhaps_promise = &$perhaps_promise;
                redo LP;
            } elsif ($perhaps_promise->isa("FP::Lazy::Promise")) {
                if (my $thunk = $$perhaps_promise[0]) {
                    my $v = force(&$thunk(), $nocache);
                    if ($$perhaps_promise[2]) {

                        if (defined(my $got = blessed($v))) {

                            $v->isa($$perhaps_promise[2])
                                or die_type_error($$perhaps_promise[2],
                                "a '$got'", $v);
                        } else {
                            die_type_error($$perhaps_promise[2],
                                "a non-object", $v);
                        }
                    }
                    unless ($nocache) {
                        $$perhaps_promise[1] = $v;
                        $$perhaps_promise[0] = undef;
                    }
                    $v
                } else {
                    $$perhaps_promise[1]
                }
            } else {
                $perhaps_promise
            }
        } else {
            $perhaps_promise
        }
    }
}

# just remove promise wrapper, don't actually force its evaluation. XX
# does this need updating for the new type feature?
sub force_noeval {
    @_ == 1 or fp_croak_arity 1;
    my ($s) = @_;
    if (defined blessed($s)) {
        if ($s->isa("FP::Lazy::Promise")) {
            if ($$s[0]) {
                $s
            } else {
                $$s[1]
            }
        } else {
            $s
        }
    } else {
        $s
    }
}

sub FORCE {
    for (@_) {
        $_ = force $_
    }
    wantarray ? @_ : $_[-1]
}

# XX because show did lead to endless loop, (why?) sgh
sub strshow {
    my ($v) = @_;
    if (defined $v) {
        require overload;
        overload::StrVal($v)
    } else {
        "undef"
    }
}

# `use overload` arguments, to prevent from accidental use as if it
# were FP::TransparentLazy

our $allow_access = 0;    # true 'turns off' the overload

sub overloads {
    my ($with_application_overload) = @_;
    (
        (
            map {
                my $ctx = $_;
                $ctx => sub {
                    $allow_access
                        ? $_[0]
                        : Carp::croak
                        "non-auto-forcing promise accessed via $ctx operation"
                }
            } ($with_application_overload ? ("&{}") : ()),

            # (XX can't overload '@{}'?)
            qw(0+ "" bool qr ${} %{} *{})
        ),
        fallback => 1
    )
}

package FP::Lazy::AnyPromise {

    *force = \&FP::Lazy::force;

    sub FORCE {
        $_[0] = FP::Lazy::force($_[0]);
    }

    sub DESTROY {

        # nothing, catch this to prevent it from entering AUTOLOAD
    }

    # XXX TODO: provide a `can` method, right?

}

use FP::Show qw(subprefix_to_show_coderef);

my $lazy_thunk_show  = subprefix_to_show_coderef("lazy ");
my $lazyT_thunk_show = subprefix_to_show_coderef("lazyT ");

package FP::Lazy::Promise {
    our @ISA = 'FP::Lazy::AnyPromise';

    use overload FP::Lazy::overloads(1);

    sub FP_Lazy_is_forced {
        not defined $_[0][0]
    }

    sub FP_Show_show {
        my ($s, $show) = @_;

        # do not force unforced promises
        if (defined $$s[0]) {
            if (defined(my $cl = $$s[2])) {
                &$lazyT_thunk_show($$s[0]) . " " . &$show($cl)
            } else {
                &$lazy_thunk_show($$s[0])
            }
        } else {
            &$show($$s[1])
        }
    }

    our $AUTOLOAD;    # needs to be declared even though magical

    sub AUTOLOAD {
        my $methodname = $AUTOLOAD;
        $methodname =~ s/.*:://;
        my $maybe_expected_ref = $_[0][2];
        my ($v, $ref);
        if (defined $maybe_expected_ref) {
            $ref = $maybe_expected_ref;
        } else {
            $v   = FP::Lazy::force($_[0]);
            $ref = ref $v;
        }

        # To be able to select special implementations for lazy
        # inputs, select a method with `stream_` prefix if present.

        # This will give "Can't call method "can" without a package or
        # object reference" exception for the empty string given as
        # type, which is happening in a weird place but actually is
        # appropriate enough, right? Leaving at that is cheaper than
        # special-casing it.

        # XX: a possibility would be to force the value even if it's a
        # lazyT, if the method isn't a lazy one. How to know if it's a
        # lazy one? stream_ prefix could double up for that,
        # possibly. Will have to provide cons as stream_cons alias,
        # then, though, for example.

        my $method
            = ($methodname =~ /^stream_/
            ? $ref->can($methodname)
            : $ref->can("stream_$methodname") // $ref->can($methodname)
                // "FP::Mixin::Utils"->can($methodname));
        if ($method) {

            # If we forced evaluation, pass on the evaluated value.
            # Can't rebuild @_ or it would break 'env clearing' ability
            # of the method. Thus assign to $_[0], which will effect
            # our env, too, but so what? XX still somewhat bad. (Is
            # like `FORCE`.)
            $_[0] = $v unless defined $maybe_expected_ref;
            goto &$method;
        } else {

            if (defined $maybe_expected_ref) {

                # If the library is declaring a base class as the type
                # of the lazyT (in the case of basically a sum type),
                # then if the user calls a method on the promise that
                # does not exist in that base class, then still force
                # it: this is also correct since in that case, the
                # method will surely *need* the forced value, since,
                # if it doesn't, it would be independent of the
                # subclass hence be in the base class. Thus: force
                # (equivalent to downgrading the lazyT to a lazy), and
                # try again.

                # $v   = FP::Lazy::force($_[0]);
                # $ref = ref $v;
                # $maybe_expected_ref = undef; # so that the logic works
                # redo ...

                # or simply adapted copy-paste:

                $v = FP::Lazy::force($_[0]);
                my $method
                    = ($methodname =~ /^stream_/
                    ? $v->can($methodname)
                    : $v->can("stream_$methodname") // $v->can($methodname)
                        // "FP::Mixin::Utils"->can($methodname));
                if ($method) {
                    $_[0] = $v;
                    goto &$method;
                }
            }

            # XX imitate perl's ~exact error message?
            Carp::croak "no method '$methodname' found for object: "
                . FP::Lazy::strshow($v);
        }
    }

    # should really have a maybe_ prefix, but since it's for debugging
    # purposes only (and in that case also likely always returns a
    # value) and we like short names for that, leave it at this, ok?
    # XXX avoid spamming with such a short name; use FP_Lazy_bt [or
    # de-priorize it like the FP::Mixin::Utils stuff?]
    sub bt {
        my $s = shift;
        $$s[2]
    }
}

my $lazyLight_thunk_show = subprefix_to_show_coderef("lazyLight ");

package FP::Lazy::PromiseLightBase {

    # Things shared with FP::TransparentLazy::PromiseLight

    our @ISA = qw(FP::Lazy::AnyPromise);

    sub FP_Lazy_is_forced {
        0
    }

    sub FP_Show_show {
        my ($s, $show) = @_;

        # do not force unforced promises
        &$lazyLight_thunk_show($s)
    }

    our $AUTOLOAD;    # needs to be declared even though magical

    sub AUTOLOAD {
        my $methodname = $AUTOLOAD;

        my $v = $_[0]->();
        $methodname =~ s/.*:://;

        # To be able to select special implementations for lazy
        # inputs, select a method with `stream_` prefix if present.

        my $method
            = ($methodname =~ /^stream_/
            ? $v->can($methodname)
            : $v->can("stream_$methodname") // $v->can($methodname)
                // "FP::Mixin::Utils"->can($methodname));
        if ($method) {

            # Can't rebuild @_ or it would break 'env clearing' ability
            # of the method. Thus assign to $_[0], which will effect
            # our env, too, but so what? XX still somewhat bad. (Is
            # like `FORCE`.)
            $_[0] = $v;
            goto &$method;
        } else {

            # XX imitate perl's ~exact error message?
            Carp::croak "no method '$methodname' found for object: "
                . FP::Lazy::strshow($v);
        }
    }

    sub bt {
        my $s = shift;
        Carp::croak "lazyLight cannot store a backtrace"

            # except if using a different implementation when $debug
            # is on
    }
}

package FP::Lazy::PromiseLight {
    our @ISA = qw(FP::Lazy::PromiseLightBase);
    use overload FP::Lazy::overloads(0);
}

1
