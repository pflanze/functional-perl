#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
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

    my $count= 0;
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
    is is_promise($b), '';
    is $b, 1/2;
    is $count, 1;

    # Note that lazy evaluation and mutation usually doesn't mix well -
    # lazy programs better be purely functional. Here $tot depends not
    # just on the inputs, but also on how many elements were evaluated:
    use FP::Stream qw(stream_map); # uses `lazy` internally
    use FP::List;
    my $tot=0;
    my $l= stream_map sub {
        my ($x)=@_;
        $tot+=$x;
        $x*$x
    }, list (5,7,8);
    is $tot, 0;
    is $l->first, 25;
    is $tot, 5;
    is $l->length, 3;
    is $tot, 20;

    # Also note that `local` does mutation (even if in a somewhat
    # controlled way):
    our $foo= "";
    sub moo {
        my ($bar)=@_;
        local $foo= "Hello";
        lazy { "$foo $bar" }
    }
    is moo("you")->force, " you";

    # runtime conditional lazyness:

    sub condprom($) {
        my ($cond)= @_;
        lazy_if { 1 / 0 } $cond
    }

    is is_promise(condprom 1), 1;

    eval {
        # immediate division by zero exception (still pays
        # the overhead of two subroutine calls, though)
        condprom 0
    };
    like $@, qr/^Illegal division by zero/;


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

    is is_promise($p), ''; # returns true iff $x holds a promise


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

FP_Show_show: instead of "DUMMY", show file/line of the thunk's
definition?

=head1 SEE ALSO

https://en.wikipedia.org/wiki/Futures_and_promises

Alternative Data::Thunk, but see note in TODO file about problems.

Alternative Scalar::Defer?

L<FP::TransparentLazy>

L<FP::Mixin::Utils> -- Lazy implements this as a fallback (lower priority than forcing the promise and finding the method on the result)

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(lazy lazy_if lazyLight force FORCE is_promise);
@EXPORT_OK=qw(delay force_noeval);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Carp;
use FP::Mixin::Utils;


our $debug= $ENV{DEBUG_FP_LAZY} ? 1 : '';

# A promise is an array with two fields:
# index 0: thunk when unevaluated, undef once evaluated
# index 1: value once evaluated
# index 2: backtrace if $debug is true

sub lazy (&) {
    bless [$_[0],
           undef,
           $debug && FP::Repl::Stack->get(1)->backtrace
          ], "FP::Lazy::Promise"
}

sub lazy_if (&$) {
    ($_[1] ?
     bless ([$_[0],
             undef,
             $debug && FP::Repl::Stack->get(1)->backtrace
            ], "FP::Lazy::Promise")
     : do {
         my ($thunk)=@_;
         @_=();
         goto $thunk;
     })
}

# not providing for caching (1-time-only evaluation)
sub lazyLight (&) {
    bless $_[0], "FP::Lazy::PromiseLight"
}

sub is_promise ($) {
    length ref $_[0] ? UNIVERSAL::isa ($_[0], "FP::Lazy::AnyPromise") : ''
}

sub delay (&);  *delay = \&lazy;
sub delayLight (&); *delayLight= \&lazyLight;


sub force ($;$) {
    my ($perhaps_promise,$nocache)=@_;
  LP: {
        if (length (my $r= ref $perhaps_promise)) {
            if (UNIVERSAL::isa ($perhaps_promise, "FP::Lazy::PromiseLight")) {
                $perhaps_promise= &$perhaps_promise;
                redo LP;
            } elsif (UNIVERSAL::isa ($perhaps_promise, "FP::Lazy::Promise")) {
                if (my $thunk= $$perhaps_promise[0]) {
                    my $v= &$thunk();
                    unless ($nocache) {
                        $$perhaps_promise[1]= $v;
                        $$perhaps_promise[0]= undef;
                    }
                    $perhaps_promise= $v;
                    redo LP;
                } else {
                    $perhaps_promise= $$perhaps_promise[1];
                    redo LP;
                }
            } else {
                $perhaps_promise
            }
        } else {
            $perhaps_promise
        }
    }
}

# just remove promise wrapper, don't actually force its evaluation
sub force_noeval ($) {
    my ($s)=@_;
    if (length (my $r= ref $s)) {
        if (UNIVERSAL::isa ($s, "FP::Lazy::Promise")) {
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


# `use overload` arguments, to prevent from accidental use as if it
# were FP::TransparentLazy

our $allow_access= 0; # true 'turns off' the overload

sub overloads {
    my ($with_application_overload)= @_;
    ((map {
        my $ctx= $_;
        $ctx=> sub {
            $allow_access ? $_[0] :
                Carp::croak "non-auto-forcing promise accessed via $ctx operation"
        }
      }
      ($with_application_overload ? ("&{}") : ()),
      # (XX can't overload '@{}'?)
      qw(0+ "" bool qr ${} %{} *{})
     ),
     fallback=> 1
    )
}

package FP::Lazy::AnyPromise {

    *force= *FP::Lazy::force;

    sub FORCE {
        $_[0] = force ($_[0]);
    }

    sub DESTROY {
        # nothing, catch this to prevent it from entering AUTOLOAD
    }

    our $AUTOLOAD; # needs to be declared even though magical
    sub AUTOLOAD {
        my $methodname= $AUTOLOAD;
        my $v= force ($_[0]);
        $methodname =~ s/.*:://;
        # To be able to select special implementations for lazy
        # inputs, select a method with `stream_` prefix if present.
        # (No need to check whether $v is a reference, as the same
        # code is valid for class names.)
        my $method=
          ($methodname=~ /^stream_/ ? UNIVERSAL::can($v, $methodname)
           : UNIVERSAL::can($v, "stream_$methodname")
           // UNIVERSAL::can($v, $methodname)
           // UNIVERSAL::can("FP::Mixin::Utils", $methodname));
        if ($method) {
            # can't change @_ or it would break 'env clearing' ability
            # of the method. Thus assign to $_[0], which will effect
            # our env, too, but so what? XX still somewhat bad.
            $_[0]= $v; goto &$method;
        } else {
            # XX imitate perl's ~exact error message?
            Carp::croak "no method '$methodname' found for object: $v";
        }
    }

    # should really have a maybe_ prefix, but since it's for debugging
    # purposes only (and in that case also likely always returns a
    # value) and we like short names for that, leave it at this, ok?
    # XXX avoid spamming with such a short name; use FP_Lazy_bt [or
    # de-priorize it like the FP::Mixin::Utils stuff?]
    sub bt {
        my $s=shift;
        $$s[2]
    }

}

use FP::Show qw(subprefix_to_show_coderef);

my $lazy_thunk_show= subprefix_to_show_coderef("lazy ");

package FP::Lazy::Promise {
    our @ISA= 'FP::Lazy::AnyPromise';

    use overload FP::Lazy::overloads(1);

    sub FP_Show_show {
        my ($s,$show)=@_;
        # do not force unforced promises
        if ($$s[0]) {
            &$lazy_thunk_show($$s[0])
        } else {
            &$show($$s[1])
        }
    }
}

my $lazyLight_thunk_show= subprefix_to_show_coderef("lazyLight ");

package FP::Lazy::PromiseLight {
    our @ISA= qw(FP::Lazy::AnyPromise);

    use overload FP::Lazy::overloads(0);

    sub FP_Show_show {
        my ($s,$show)=@_;
        # do not force unforced promises
        &$lazyLight_thunk_show($s)
    }
}


1
