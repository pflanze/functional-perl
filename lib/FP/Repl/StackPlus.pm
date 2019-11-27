#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl::StackPlus - Stack including lexical variables

=head1 SYNOPSIS

 my $stack= FP::Repl::StackPlus->get($numbers_of_levels_to_skip);
 # same as FP::Repl::Stack, but frames also have `lexicals`, a hash
 # as delivered from PadWalker

=head1 DESCRIPTION

I'm pretty sure this is still re-inventing some wheel...

=head1 SEE ALSO

L<FP::Repl::Stack>, L<PadWalker>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Repl::StackPlus;

use strict; use warnings; use warnings FATAL => 'uninitialized';

{
    package FP::Repl::Repl::StackPlusFrame;

    use FP::Repl::Stack; # so that FP::Struct won't try to load
                          # FP/Repl/StackFrame.pm

    use FP::Struct ["lexicals"], "FP::Repl::StackFrame";

    # CAREFUL: equal stackframes still don't need to be the *same*
    # stackframe!
    sub equal {
        my $s=shift;
        my ($v)=@_;
        die "not implemented (yet?)";
    }

    _END_
}


use PadWalker qw(peek_my);

# TODO/XXX: see comments in commit 'StackPlus: don't die in peek_my
# (HACK)'; this should be replaced with something clean /
# investigated.
our $maybe_peek_my= sub {
    my ($skip)=@_;
    my $res;
    if (eval {
        $res= peek_my ($skip);
        1
    }) {
        $res
    } else {
        my $e= $@;
        if ($e=~ /^Not nested deeply enough/i) {
            undef
        } else {
            die $e
        }
    }
};

use FP::Struct [], "FP::Repl::Stack";

# XX ugly, modified COPY from FP::Repl::Stack
sub get {
    my $class=shift;
    my ($skip)=@_;
    package DB; # needs to be outside loop or it won't work. Wow Perl.
    my @frames;
    while (my @vals=caller($skip)) {
        my $subargs= [ @DB::args ];
        # XX how to handle this?: "@DB::args might have
        # information from the previous time "caller" was
        # called" (perlfunc on 'caller')
        push @frames, FP::Repl::Repl::StackPlusFrame->new
          ($subargs, @vals, &$maybe_peek_my($skip+2));
        $skip++;
    }
    $class->new(\@frames);
}


*lexicals= &$FP::Repl::Stack::make_frame_accessor ("lexicals");
*perhaps_lexicals= &$FP::Repl::Stack::make_perhaps_frame_accessor ("lexicals");

_END_
