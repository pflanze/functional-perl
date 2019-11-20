#
# Copyright (c) 2007-2019 Christian Jaeger, copying@christianjaeger.ch
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

This is alpha software! Read the package README.

=cut


package Chj::Unix::Exitcode;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(exitcode);
@EXPORT_OK=qw(exitcode);
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict; use warnings; use warnings FATAL => 'uninitialized';

package Chj::Unix::Exitcode::Exitcode {

    use Chj::Unix::Signal;

    use Class::Array -fields=>
      -publica=>
      'code',
      ;


    sub new {
        my $class=shift;
        my $s= $class->SUPER::new;
        ($$s[Code])=@_;
        $s
    }

    sub as_string {
        my $s=shift;
        my $code= $$s[Code];
        if ($code < 256) {
            "signal $code (".Chj::Unix::Signal->new($code)->as_string.")"
        } else {
            if (($code & 255) == 0) {
                "exit value ".($code >> 8)
            } else {
                warn "does this ever happen?";
                "both exit value and signal ($code)"
            }
        }
    }

    end Class::Array;
}


sub exitcode ( $ ) {
    my ($code)=@_;
    Chj::Unix::Exitcode::Exitcode->new($code)->as_string;
}

1
