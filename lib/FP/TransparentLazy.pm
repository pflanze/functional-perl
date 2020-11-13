#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
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

    my $a = lazy { 1 / 0 };
    like((eval {
        # $a's evaluation is forced here
        print $a
    } || $@), qr/division by zero/);

    # etc., see SYNOPSIS in FP::Lazy but remove the `force` and `FORCE`
    # calls

=head1 DESCRIPTION

This implements a variant of FP::Lazy that forces promises
automatically upon access (and writes their result back to the place
they are forced from, like FP::Lazy's `FORCE` does). Otherwise the two
are fully interchangeable.

NOTE: this is EXPERIMENTAL. Also, should this be merged with
Data::Thunk ?

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

our @EXPORT      = qw(lazy lazyLight force FORCE is_promise);
our @EXPORT_OK   = qw(delay);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Lazy qw(force FORCE is_promise);    # for re-export

sub lazy (&) {
    bless [$_[0], undef], "FP::TransparentLazy::Promise"
}

# not providing for caching (1-time-only evaluation)
sub lazyLight (&) {
    bless $_[0], "FP::TransparentLazy::PromiseLight"
}

sub delay (&);
*delay = \&lazy;
sub delayLight (&);
*delayLight = \&lazyLight;

package FP::TransparentLazy::Overloads {
    use overload(
        (map { $_ => "FORCE" } split / +/, '"" 0+ bool qr &{} ${} %{} *{}'),

        # XX hm, can't overload '@{}', why?
        fallback => 1
    );
}

package FP::TransparentLazy::Promise {
    our @ISA = qw(FP::TransparentLazy::Overloads
        FP::Lazy::Promise);
}

package FP::TransparentLazy::PromiseLight {
    our @ISA = qw(FP::TransparentLazy::Overloads
        FP::Lazy::PromiseLight);
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
