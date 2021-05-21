#
# Copyright (c) 2015-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::TransparentLazy - lazy evaluation with transparent evaluation

=head1 SYNOPSIS

    use FP::TransparentLazy;

    # This is the same SYNOPSIS as in FP::Lazy but with most `force`
    # calls removed, and slightly differing behaviour in places
    # (e.g. `$a + 2` will evaluate the thunk here and thus give
    # division by zero):

    my $a = lazy { 1 / 0 };
    eval {
        # $a's evaluation is forced here
        print $a
    };
    like $@, qr/^Illegal division by zero/;

    eval {
        $a + 2
    };
    like $@, qr/^Illegal division by zero/;

    my $count = 0;
    my $b = lazy { $count++; 1 / 2 };
    is is_promise($b), 1;
    is $count, 0;
    is $b, 1/2; # increments $count
    is $count, 1;
    # $b is still a promise at this point (although an evaluated one):
    is is_promise($b), 1;
    is $b, 1/2; # does not increment $count anymore
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

    # Also note that `local` does mutation (even if in a somewhat
    # controlled way):
    our $foo = "";
    sub moo {
        my ($bar) = @_;
        local $foo = "Hello";
        lazy { "$foo $bar" }
    }
    is moo("you")->force, " you";
    is moo("you"), " you";

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

    # A `lazyLight` promise is re-evaluated on every access:
    my $z = 0;
    my $v = lazyLight { $z++; 3*4 };
    is $v, 12;
    is $z, 1;
    is $v, 12;
    is $z, 2;
    is force($v), 12;
    is $z, 3;
    is $v, 12;
    is $z, 4;

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
    is $z, 5;
    is $v, 12;
    is $z, 5; # you can see that re-evaluation has stopped
    ok not ref $v;

=head1 DESCRIPTION

This implements a variant of FP::Lazy that forces promises
automatically upon access (and writes their result back to the place
they are forced from, like FP::Lazy's `FORCE` does, except in the
lazyLight case where `FORCE` is consciously not used automatically to
keep more consistent re-evaluation behaviour). Otherwise the two are
fully interchangeable.

NOTE: this is EXPERIMENTAL. Also, should this be merged with
L<Data::Thunk>? OTOH, should remain interchangeable with L<FP::Lazy>,
and maybe merged with that one.

The drawback of transparency might be more confusion, as it's not
directly visible anymore (neither in the debugger nor the source code)
what's lazy. Also, transparent forcing will be a bit more expensive
CPU wise. Please give feedback about your experiences!

=head1 SEE ALSO

L<FP::Lazy>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::TransparentLazy;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(lazy lazy_if lazyLight force FORCE is_promise);
our @EXPORT_OK   = qw(delay lazy_backtrace);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Lazy qw(force FORCE is_promise lazy_backtrace);    # for re-export

our $eager = ($ENV{DEBUG_FP_LAZY} and $ENV{DEBUG_FP_LAZY} =~ /^eager$/i);
our $debug = $ENV{DEBUG_FP_LAZY} ? (not $eager) : '';

sub lazy (&) {
    $eager
        ? goto $_[0]
        : bless [$_[0], undef, $debug && FP::Repl::Stack->get(1)->backtrace],
        "FP::TransparentLazy::Promise"
}

sub lazy_if (&$) {
    (
        ($_[1] and not $eager)
        ? bless([$_[0], undef, $debug && FP::Repl::Stack->get(1)->backtrace],
            "FP::TransparentLazy::Promise")
        : do {
            my ($thunk) = @_;
            @_ = ();
            goto $thunk;
        }
    )
}

# not providing for caching (1-time-only evaluation)
sub lazyLight (&) {
    $eager ? goto $_[0] : bless $_[0], "FP::TransparentLazy::PromiseLight"
}

sub delay (&);
*delay = \&lazy;
sub delayLight (&);
*delayLight = \&lazyLight;

# XX to make it truly transparent, should always overload '&{}'; but
# then how to force it without getting into an infinite loop? No way
# to turn off the overload (except reblessing)?

# XX hm, can't overload '@{}', why?
sub overloads {
    my ($with_application_overload) = @_;
    ($with_application_overload ? ('&{}') : ()), qw'"" 0+ bool qr ${} %{} *{}';
}

package FP::TransparentLazy::Promise {
    our @ISA = qw(FP::Lazy::Promise);
    use overload((map { $_ => "FORCE" } FP::TransparentLazy::overloads(1)),
        fallback => 1);
}

# Do *not* call "FORCE" method for PromiseLight if the aim is to
# re-evaluate it every time.
sub forceLight {
    &{ $_[0] }
}

package FP::TransparentLazy::PromiseLight {
    our @ISA = qw(FP::Lazy::PromiseLightBase);
    use overload(
        (
            map { $_ => \&FP::TransparentLazy::forceLight }
                FP::TransparentLazy::overloads(0)
        ),
        fallback => 1
    );
}

use Chj::TEST;

our $c;
TEST {
    $c = lazy {
        sub {"foo"}
    };
    ref $c
}
'FP::TransparentLazy::Promise';
TEST { &$c() }
"foo";
TEST { ref $c }
"CODE";

1
