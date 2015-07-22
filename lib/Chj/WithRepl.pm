#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::WithRepl

=head1 SYNOPSIS

 use Chj::WithRepl;
 withrepl { die "foo"; };  # shows the exception, then runs a repl
                           # within the exception context

 push_withrepl (0); # turn on using a repl globally, but storing the
                    # previous handler on a stack; the argument says
                    # how many levels from the current one to go back
                    # for the search of 'eval' (the WORKAROUND, see
                    # below)

 WithRepl_eval ...; # like `eval` but transparent for WithRepl
                    # handlers

 pop_withrepl; # restore the handler that was pushed last.


=head1 DESCRIPTION

Sets `$SIG{__DIE__}` to a wrapper that shows the exception then calls
a repl from L<Chj::repl>. This means, when getting an exception,
instead of terminating the program (with a message), you get a chance
to inspect the program state interactively.

Note that it currently employs a WORKAROUND to check from within the
sig handler whether there's a new `(eval)` frame on the stack between
the point of the handler call and the point of the handler
installation (or n frames back from there, as per the argument to
`push_withrepl`).

=cut


package Chj::WithRepl;

@ISA="Exporter"; require Exporter;
@EXPORT=qw(withrepl push_withrepl pop_withrepl);
@EXPORT_OK=qw(WithRepl_eval);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

#-- moved up here before any lexicals to avoid their exposure--
# Wrapping `eval` calls with a special frame
# (`Chj::WithRepl::WithRepl_eval`) that the handler can test for:

sub WithRepl_eval ($;$) {
    my ($arg, $maybe_package)=@_;
    if (ref $arg) {
	eval { &$arg() }
    } else {
	my $package= $maybe_package // caller;
	eval "package $package; $arg"
    }
}


use Chj::repl;
use Chj::TEST;


# PROBLEM: even exceptions within contexts that catch exceptions
# (i.e. `eval { }`) are invoking a repl, unless we use a workaround.

# XXX this will be worrysome slow, and on top of that slower for
# bigger stack depths, easily turning algorithms into O(n^2)! Needs a
# solution in XS.

sub current_user_frame ($) {
    my ($skip)=@_;
    if ($skip) { $skip >= 0 or die "expecting maybe(natural0), got '$skip'"; }
    my @v;
    my $i= 0;
    while ((@v)= caller ($i++)) {
	if ($v[0] ne "Chj::WithRepl") {
	    if ($skip) {
		unless ((@v) = caller ($i + $skip)) {
		    die "skip value goes beyond the end of the stack";
		}
	    }
	    return Chj::Util::Repl::StackFrame->new(undef, @v);
	}
    }
    die "???"
}


# have_eval_since_frame: is ignoring eval from repl. Uh, so hacky. But
# otherwise how to enable WithRepl from within a repl? With a special
# repl command? But even when previously the handler was enabled, a
# new repl should never be disabling it. (It should not change the
# handler, just change the catch point. But other exception catchers
# should change the haandler, but don't, which is the reason we need
# to analyze here.)

our $debug = 0;

sub have_eval_since_frame ($) {
    my ($startframe)= @_;

    my @v;
    my $i=1;

  SKIP: {
	while ((@v)= caller $i++) {
	    last SKIP if ($v[0] ne "Chj::WithRepl");
	}
	die "???"
    }

    do {
	my $f= Chj::Util::Repl::StackFrame->new(undef, @v);
	if ($f->equal ($startframe)) {
	    warn "reached startframe, thus return false"
	      if $debug;
	    return ''
	} elsif ($f->subroutine eq "(eval)") {
	    if ((@v)= caller $i++) {
		my $f= Chj::Util::Repl::StackFrame->new(undef, @v);
		my $sub= $f->subroutine;
		if ($sub eq 'Chj::Util::Repl::myeval'
		    or
		    $sub eq 'main::myxeval_in' # repl script, even
		    # more of hack.
		   ) {
		    warn "(ignore eval since it's from a repl)"
		      if $debug;
		} elsif ($sub eq 'Chj::WithRepl::WithRepl_eval') {
		    warn "(ignore eval since it's from a WithRepl_eval)"
		      if $debug;
		} elsif ($sub =~ /::BEGIN\z/) {
		    # (why does BEGIN use eval?)
		    warn "(ignore eval since it's from a BEGIN)"
		      if $debug;
		} else {
		    warn "GOT eval (standalone)"
		      if $debug;
		    return 1
		}
	    } else {
	        warn "GOT eval right at end of stack"
		  if $debug;
		return 1
	    }
	}
    }
      while ((@v)= caller $i++);

    warn "couldn't find orig frame!"
      if $debug;
      # not even tail-calling should be able to do that, unless, not
      # local'ized, hm XXX non-popped handler.
    0
}



sub handler_for ($$) {
    my ($startframe, $orig_handler)=@_;
    sub {
	my ($e)=@_;
	# to show local errors with backtrace:
	# require Chj::Backtrace; import Chj::Backtrace;
	if (have_eval_since_frame $startframe) {
	    #$SIG{__DIE__}= $orig_handler;
	    # ^ helps against the loop but makes the push_withrepl
	    #   one-shot, of course
	    #goto &{$orig_handler // sub { die $_[0] }}  nah, try:
	    if (defined $orig_handler) {
		#goto $orig_handler
		# ^ just doesn't work, seems to undo the looping
		#   protection. so..:
		&$orig_handler ($e)
	    } else {
		#warn "no orig_handler, returning";
		return
	    }
	} else {
	    print STDERR "Exception: $e";
	    # then what to do upon exiting it? return the value of the repl?
	    # Ehr, XX repl needs new feature, a "quit this context with this value".
	    repl(1)
	}
    }
}

sub handler ($) {
    my ($skip)= @_;
    handler_for (current_user_frame($skip),
		 $SIG{__DIE__})
}

sub withrepl (&) {
    local $SIG{__DIE__}= handler (0);
    &{$_[0]}()
}


TEST { withrepl { 1+2 } }
 3;
TEST { [ withrepl { "hello", "world" } ] }
  [ 'hello', 'world' ];


our @stack;

sub push_withrepl ($) {
    my ($skip)= @_;
    push @stack, $SIG{__DIE__};
    $SIG{__DIE__}= handler ($skip);
}

sub pop_withrepl () {
    $SIG{__DIE__}= pop @stack;
}


1

