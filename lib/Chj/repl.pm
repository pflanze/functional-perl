#
# Copyright (c) 2004-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::repl - read-eval-print loop

=head1 SYNOPSIS

 use Chj::repl;
 repl;
 # -or-
 use Chj::repl();
 Chj::repl();

 # pass parameters (any fields of the Chj::Repl class):
 repl (skip=> 3, # skip 3 caller frames (when the repl call is nested
                 # within something you dont't want the user to see)
       tty=> $fh, # otherwise repl tries to open /dev/tty, or if that fails,
                  # uses readline defaults (which is somewhat broken?)
       # also, any fields of the Chj::Repl class are possible:
       maxHistLen=> 100, prompt=> "foo>", package=> "Foo::Bar",
       maybe_historypath=> ".foo_history", pager=> "more"
       # etc.
      );

=head1 DESCRIPTION

For a simple parameterless start of `Chj::Repl`.

=head1 SEE ALSO

L<Chj::Repl>: the class implementing this

=cut


package Chj::repl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(repl);
@EXPORT_OK=qw(maybe_tty);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;
use Chj::Repl;

sub maybe_tty {
    my $path= "/dev/tty";
    if (open my $fh, "+>", $path) {
	$fh
    } else {
	warn "opening '$path': $!";
	undef
    }
}

sub repl {
    @_ % 2 and die "expecting even number of arguments";
    my %args= @_;
    my $maybe_skip= delete $args{skip};
    my $maybe_tty= delete $args{tty};

    my $r= new Chj::Repl;

    if (exists $args{maybe_settingspath}) {
	my $maybe_settingspath= delete $args{maybe_settingspath};
	$r->maybe_settingspath($maybe_settingspath);
    }

    $r->possibly_restore_settings;

    # Since `Term::Readline::Gnu`'s `OUT` method does not actually
    # return the filehandle that the readline library is using,
    # instead get the tty ourselves and set it explicitely. Stupid.
    if (defined (my $still_maybe_tty= $maybe_tty // maybe_tty)) {
	$r->set_maybe_input ($still_maybe_tty);
	$r->set_maybe_output ($still_maybe_tty);
    }

    for (keys %args) {
	my $m= "set_$_";
	$r->$m($args{$_});
    }

    #$r->run ($maybe_skip);
    my $m= $r->can("run"); @_=($r, $maybe_skip); goto &$m
}

*Chj::repl= \&repl;

1
