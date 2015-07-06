#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

Chj::xIO - exception-throwing I/O wrappers (and utilities)

=head1 SYNOPSIS

=head1 DESCRIPTION

Much simpler procedures than my extensive OO based Chj::IO::File and
Chj::xopen modules.

=cut


package Chj::xIO;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(capture_stdout capture_stdout_);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub capture_stdout_ {
    my ($thunk)=@_;
    my $buf="";
    open my $out, ">", \$buf
      or die $!;
    {
	# XX threadsafe or not?
	local *STDOUT= $out;
	&$thunk; # dropping results
    }
    close $out
      or die $!;
    $buf
}

sub capture_stdout (&) {
    capture_stdout_(@_)
}


1
