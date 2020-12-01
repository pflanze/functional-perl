#
# Copyright (c) 2007-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Unix::Exitcode

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::Unix::Exitcode;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(exitcode);
our @EXPORT_OK   = qw(exitcode);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use FP::Carp;

package Chj::Unix::Exitcode::Exitcode {

    use Chj::Unix::Signal;

    use Chj::Class::Array -fields => -publica => 'code',
        ;

    sub new {
        my $class = shift;
        my $s     = $class->SUPER::new;
        ($$s[Code]) = @_;
        $s
    }

    sub as_string {
        my $s    = shift;
        my $code = $$s[Code];
        if ($code < 256) {
            "signal $code (" . Chj::Unix::Signal->new($code)->as_string . ")"
        } else {
            if (($code & 255) == 0) {
                "exit value " . ($code >> 8)
            } else {
                warn "does this ever happen?";
                "both exit value and signal ($code)"
            }
        }
    }

    end Chj::Class::Array;
}

sub exitcode {
    @_ == 1 or fp_croak_arity 1;
    my ($code) = @_;
    Chj::Unix::Exitcode::Exitcode->new($code)->as_string;
}

1
