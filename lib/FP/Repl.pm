#
# Copyright (c) 2004-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl - read-eval-print loop

=head1 SYNOPSIS

    use FP::Repl;
    repl;

    # pass parameters (any fields of the FP::Repl::Repl class):
    repl (skip=> 3, # skip 3 caller frames (when the repl call is nested
                    # within something you dont't want the user to see)
          tty=> $fh, # otherwise repl tries to open /dev/tty, or if that fails,
                     # uses readline defaults (which is somewhat broken?)
          # also, any fields of the FP::Repl::Repl class are possible:
          maxHistLen=> 100, maybe_prompt=> "foo>", maybe_package=> "Foo::Bar",
          maybe_historypath=> ".foo_history", pager=> "more"
          # etc.
         );

=head1 DESCRIPTION

For a simple parameterless start of `FP::Repl::Repl`.

=head1 SEE ALSO

L<FP::Repl::Repl>: the class implementing this

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Repl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(repl);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use FP::Repl::Repl;

sub repl {
    @_ % 2 and die "expecting even number of arguments";
    my %args= @_;
    my $maybe_skip= delete $args{skip};
    my $maybe_tty= delete $args{tty};

    my $r= new FP::Repl::Repl;

    if (exists $args{maybe_settingspath}) {
        $r->set_maybe_settingspath(delete $args{maybe_settingspath});
    }

    $r->possibly_restore_settings;

    for (keys %args) {
        my $m= "set_$_";
        $r->$m($args{$_});
    }

    #$r->run ($maybe_skip);
    my $m= $r->can("run"); @_=($r, $maybe_skip); goto &$m
}

*FP::Repl= \&repl;

1
