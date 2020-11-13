#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::fix -- recurse with the fix point combinator

=head1 SYNOPSIS

    use FP::fix;

    sub fact {
        my ($z) = @_;
        my $f = fix sub {
            my ($f,  $x, $y) = @_;
            $x > 0 ? $f->($x-1, $x*$y) : $y
        };
        $f->($z, 1)
    }
    is fact(5), 120;


=head1 DESCRIPTION

fix takes a function and returns another function that when called
calls the original function and gives it the fix'ed function as first
argument and then the original arguments.

This allows to write self-recursive local functions without having to
deal with the problem of reference cycles that self-referencing
closures would run into.

The example from the synopsis is equivalent to:

    use Scalar::Util 'weaken';

    sub fact2 {
        my ($z) = @_;
        my $f; $f = sub {
            my ($x, $y) = @_;
            $x > 0 ? $f->($x-1, $x*$y) : $y
        };
        my $_f = $f; weaken $f;
        $f->($z, 1)
    }
    is fact2(5), 120;


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::fix;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(fix fixn);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

# Alternative implementations:

# Y combinator
*Y = do {
    my $fix0 = sub {
        my ($fix0, $f) = @_;
        sub {
            @_ = (&$fix0($fix0, $f), @_);
            goto &$f;
        }
    };

    sub ($) {
        my ($f) = @_;
        &$fix0($fix0, $f)
    }
};

# Haskell recursive let based implementation:
#   XXX move this code to separate file to avoid dependencies

#   fix f = let x = f x in x

use FP::TransparentLazy qw(lazy lazyLight);

# this variant is different since it requires $f to be curried
*haskell_curried = sub {
    my ($f) = @_;
    my $x;
    $x = &$f(lazy {$x});    # can't use lazyLight here, why?
    $x
};

use Chj::TEST;
TEST {
    my $f = haskell_curried(sub {
        my ($self) = @_;
        sub {
            my ($x) = @_;
            $x > 0 ? $x * &$self($x - 1) : 1
        }
    });
    [&$f(0), &$f(3)]
}
[1, 6];

*haskell_uncurried = sub {
    my ($f) = @_;
    my $fc = sub {
        my ($fc) = @_;
        sub {
            unshift @_, $fc;
            goto &$f;
        };
    };
    my $x;
    $x = &$fc(lazy {$x});    # can't use lazyLight here, why?
    $x
};

# indirectly self-referencing through package variable
*rec = sub ($) {
    my ($f) = @_;
    sub {
        #@_ = (fix ($f), @_); goto &$f;
        unshift @_, fix($f);
        goto &$f;
    }
};

# directly locally self-referencing

use Scalar::Util 'weaken';

*weakcycle = sub ($) {
    my ($f) = @_;
    my $f2;
    $f2 = sub {
        unshift @_, $f2;
        goto &$f
    };
    my $f2_ = $f2;
    weaken $f2;
    $f2_
};

# choose implementation:

sub fix ($);

*fix = *weakcycle;

# n-ary version:

sub fixn {
    my (@f) = @_;
    my @ff;
    for (my $i = 0; $i < @f; $i++) {
        my $f = $f[$i];
        $ff[$i] = sub {
            unshift @_, @ff;
            goto &$f;
        }
    }
    my @ff_ = @ff;

    # weaken $_ for @ff;
    # ^ XXX: releases too early, same issue as
    #   mentioned in `intro/more_tailcalls`
    wantarray ? @ff_ : do {
        @ff == 1 or die "fixn: got multiple arguments, but scalar context";
        $ff_[0]
    }
}

1
