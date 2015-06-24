#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::WithRepl

=head1 SYNOPSIS

 use Chj::WithRepl;
 withrepl { die "foo"; };  # shows the exception, then runs a repl
                           # within the exception context

 push_withrepl; # turn on using a repl globally, but storing the
                # previous handler on a stack
 pop_withrepl; # restore the handler that was pushed last.


=head1 DESCRIPTION

Sets `$SIG{__DIE__}` to a wrapper that shows the exception then calls
a repl from L<Chj::repl>. This means, when getting an exception,
instead of terminating the program (with a message), you get a chance
to inspect the program state interactively.

PROBLEM: even exceptions within contexts that catch exceptions
(i.e. `eval { }`) are invoking a repl. HOW TO SOLVE THIS, SIGH?

=cut


package Chj::WithRepl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(withrepl push_withrepl pop_withrepl);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::repl;
use Chj::TEST;

sub handler {
    my ($e)=@_;
    print STDERR "$e";
    # then what to do upon exiting it? return the value of the repl? 
    # Ehr, XX repl needs new feature, a "quit this context with this value".
    repl(1)
}

sub withrepl (&) {
    local $SIG{__DIE__}= \&handler;
    &{$_[0]}()
}


TEST { withrepl { 1+2 } }
 3;
TEST { [ withrepl { "hello", "world" } ] }
  [ 'hello', 'world' ];


our @stack;

sub push_withrepl () {
    push @stack, $SIG{__DIE__};
    $SIG{__DIE__}= \&handler;
}

sub pop_withrepl () {
    $SIG{__DIE__}= pop @stack;
}

1
