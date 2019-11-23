#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xIO - some IO utilities

=head1 SYNOPSIS

    use Chj::xIO qw(
       capture_stdout capture_stdout_
       capture_stderr capture_stderr_
       );

    is capture_stdout { print "Hi!" }, "Hi!";
    is substr(capture_stderr { warn "nah" }, 0,3), "nah";

    # if you want to avoid the '&' prototype:
    is capture_stdout_(sub { print "Hi!" }), "Hi!";

=head1 DESCRIPTION

Oh, but there's Capture::Tiny ! Even uses the same names. TODO: move
to that. Although, Capture::Tiny might be using 'dup', which would not
be thread safe. Shrug.

=head1 NOTE

This is alpha software! Read the package README.

=cut


package Chj::xIO;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
    capture_stdout capture_stdout_
    capture_stderr capture_stderr_
    );
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
        &$thunk(); # dropping results
    }
    close $out
      or die $!;
    $buf
}

sub capture_stdout (&) {
    capture_stdout_(@_)
}

# stupid COPY-PASTE

sub capture_stderr_ {
    my ($thunk)=@_;
    my $buf="";
    open my $out, ">", \$buf
      or die $!;
    {
        # XX threadsafe or not?
        local *STDERR= $out;
        &$thunk(); # dropping results
    }
    close $out
      or die $!;
    $buf
}

sub capture_stderr (&) {
    capture_stderr_(@_)
}


1
