#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::noLazy - make lazy syntax non-lazy

=head1 SYNOPSIS

    use FP::noLazy; # instead of: use FP::Lazy;

    eval {
        lazy { 1 / 0 };
    };
    like $@, qr/division by zero/;

    my $x = lazy { 123*456 };
    ok !is_promise $x; # currently; see 'BUGS'
    is $x, 56088;

=head1 DESCRIPTION

Lazy evaluation is very useful to change the valuation order in purely
functional programs. It can also make debugging confusing, as the
order in which lazy expressions are evaluated depends on how they are
being used, unlike in non-lazy (eager, imperative) programming, where
evaluation order is directly visible from reading the program code.

For this reason, it can be helpful to temporarily disable lazy
evaluation. This can mean that a program isn't as efficient as it
would be, that it allocates lots of memory, or even runs out of
memory, but seeing how it behaves may point out the programming
error. So this is one tool to debug lazy functional programs. (Other
tools are enabing debug mode, see "DEBUGGING" in L<FP::Lazy> to see
the contexts in which promises were created, splitting the program
into smaller pieces, adding warn statements.)

Turning off lazy evaluation globally can be problematic, since it also
changes e.g. L<FP::Stream> or L<FP::IOStream> to evaluate eagerly,
which can lead to the program running out of memory before reaching
the stages to be debugged. Changing `lazy` to `lazy_if` (from
L<FP::Lazy>) can be tedious. Importing `lazy` (and the other lazy
forms) from L<FP::noLazy> instead of L<FP::Lazy> turns all lazy
statements in the current module to normal non-lazy (eager) ones,
i.e. the program then behaves as if the lazy forms weren't used at
all. You can now debug the program "as normal".

=head1 BUGS

As mentioned above, your program can use more memory or run out of
memory when using this module. If that happens, instead go back to
using L<FP::Lazy> and instead use `lazy_if` selectively to track down
the bugs.

`lazy` etc. from this module don't (currently) wrap the result of the
computation in a promise. This means that `is_promise` will return
false. This could lead your program to behave differently, although
maybe that should be considered a bug in your program. If you think
otherwise, please tell, and this module could be changed to still use
promise wrappers (even though they are already-evaluated). (It would
also be possible to configure this behaviour.)

=head1 SEE ALSO

L<FP::Lazy>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::noLazy;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT = qw(lazy lazyT lazy_if lazyT_if lazyLight force FORCE is_promise);
our @EXPORT_OK   = qw(delay force_noeval lazy_backtrace is_forced);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Docstring;

# For re-export:
use FP::Lazy qw(is_forced lazy_backtrace is_promise force force_noeval FORCE);

sub lazy (&) {
    __ '`lazy { expr }`: NOTE: this is a noop as this is the variant
        from FP::noLazy!';
    goto $_[0]
}

sub lazyT (&$) {
    __ '`lazyT { expr } $classname`: expr must return an object that
        satisfies ->isa($classname). NOTE: this is the variant from
        FP::noLazy, hence is evaluating immediately!';
    goto $_[0]

        # XXX still type-check, right? and do the same in FP::Lazy?
}

sub lazy_if (&$) {
    __ '`lazy_if { expr } $boolean`: NOTE: this is the variant from
        FP::noLazy, hence evaluates expr always immediately,
        regardless of $boolean!';
    goto $_[0]
}

sub lazyT_if (&$$) {
    __ '`lazyT_if { expr } $classname, $boolean`: expr must return an
        object that satisfies ->isa($classname); NOTE: this is the
        variant from FP::noLazy, hence evaluates expr always
        immediately, regardless of $boolean!';
    goto $_[0]

        # XXX still type-check, right? and do the same in FP::Lazy?
}

# not providing for caching (1-time-only evaluation)
sub lazyLight (&) {
    __ 'NOTE: this is the variant from FP::noLazy, hence evaluates
        expr always immediately!';
    goto $_[0]
}

sub delay (&);
*delay = \&lazy;
sub delayLight (&);
*delayLight = \&lazyLight;

1
