#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Repl::StackPlus - Stack including lexical variables

=head1 SYNOPSIS

 my $stack= Chj::Repl::StackPlus->get($numbers_of_levels_to_skip);
 # same as Chj::Repl::Stack, but frames also have `lexicals`, a hash
 # as delivered from PadWalker

=head1 DESCRIPTION

I'm pretty sure this is still re-inventing some wheel...

=head1 SEE ALSO

L<Chj::Repl::Stack>, L<PadWalker>

=cut


package Chj::Repl::StackPlus;

use strict; use warnings; use warnings FATAL => 'uninitialized';

{
    package Chj::Repl::StackPlusFrame;

    use Chj::Repl::Stack; # so that FP::Struct won't try to load
                          # Chj/Repl/StackFrame.pm

    use FP::Struct ["lexicals"], "Chj::Repl::StackFrame";

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

use FP::Struct [], "Chj::Repl::Stack";

# XX ugly, modified COPY from Chj::Repl::Stack
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
	push @frames, Chj::Repl::StackPlusFrame->new
	  ($subargs, @vals, &$maybe_peek_my($skip+2));
	$skip++;
    }
    $class->new(\@frames);
}


*lexicals= &$Chj::Repl::Stack::make_frame_accessor ("lexicals");
*perhaps_lexicals= &$Chj::Repl::Stack::make_perhaps_frame_accessor ("lexicals");

_END_
