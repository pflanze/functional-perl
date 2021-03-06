#
# Copyright (c) 2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Carp - report to immediate caller

=head1 SYNOPSIS

    use FP::Carp;

    # Like `croak` but don't skip any parent call frames:
    sub foo {
        @_ == 1 or fp_croak "I need 1 argument";
    }

    # Easier if you just want to report an error about the number of
    # arguments passed to the current subroutine:
    sub bar {
        @_ == 2 or fp_croak_arity 2;
    }

    sub test {
        foo(@_);
        bar(@_);
    }
    sub try(&) {
        eval { &{$_[0]}; 1 } && return;
        my $e= $@;
        $e=~ s/\n.*//s;
        $e=~ s{\\}{/}sg; # convert windows to unix paths
        $e
    }
    is try { test(10) }, 'bar: needs 2 arguments (got 1) at lib/FP/Carp.pm line 31';
    is try { test(10,11) }, 'I need 1 argument at lib/FP/Carp.pm line 30';

    # there is currently no equivalent to `carp`, or `confess` (use
    # Devel::Confess instead?)

=head1 DESCRIPTION

L<Carp> skips call frames in the same package as the caller of `croak`
(or `carp` etc.), as well as those from matching some other cases like
parent classes. This works well when assuming that all the code that's
being skipped is correct, and the error has to do with the code
outside those scopes. This is also necessary when not using tail-call
optimization (as via goto \&sub, or L<Sub::Call::Tail>) to skip parent
calls in tail position.

But for cases like checking the number of arguments to the current
subroutine, this is not useful, as the error really is in the
immediate caller. And if using tail-call optimization, just reporting
the next frame is also correct in other cases when the current call is
in the caller's tail position.

This provides L<Carp> like subroutines for these cases--they go up
exactly one frame, no matter what.

Since there's no logic for skipping of call frames, this module is
simpler than L<Carp>.


=head1 SEE ALSO

L<Carp>, L<FP::Repl>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Carp;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(fp_croak fp_croak_arity);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

sub fp_croak {
    my $msg = join("", @_);

    my @f1        = caller(1);
    my $reportloc = "$f1[1] line $f1[2]";
    die "$msg at $reportloc\n"
}

sub fp_croak_arity {
    @_ <= 1 or warn "fp_croak_arity: wrong number of arguments";
    my ($maybe_n) = @_;

    # maybe_n can be a range, or really any string.

    my $msg = do {
        if (defined $maybe_n) {
            my $argumentS = $maybe_n eq "1" ? "argument" : "arguments";
            "needs $maybe_n $argumentS"
        } else {
            "wrong number of arguments"
        }
    };
    my @f1;
    my $nargs1;
    {

        package DB;
        @f1     = caller(1);
        $nargs1 = @DB::args;
    }
    my $subname = $f1[3];
    $subname =~ s/^.*:://s;
    my $reportloc = "$f1[1] line $f1[2]";
    die "$subname: $msg (got $nargs1) at $reportloc\n"
}

1
