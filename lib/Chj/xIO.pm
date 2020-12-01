#
# Copyright (c) 2013-2020 Christian Jaeger, copying@christianjaeger.ch
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

    use Chj::xIO qw(with_output_to_file);
    my $res = with_output_to_file(".xIO-test-out", sub { print "Hi"; 123 });
    is $res, 123;
    is do { open my $in, "<", ".xIO-test-out"; local $/; <$in> }, "Hi";

=head1 DESCRIPTION

Oh, there's Capture::Tiny ! Even uses the same names. TODO: move to
that. Although, Capture::Tiny might be using 'dup', which would not be
thread safe.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xIO;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(
    capture_stdout capture_stdout_
    capture_stderr capture_stderr_
    with_output_to_file
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Carp;

sub capture_stdout_ {
    my ($thunk) = @_;
    my $buf = "";
    open my $out, ">", \$buf or die $!;
    {
        # XX threadsafe or not?
        local *STDOUT = $out;
        &$thunk();    # dropping results
    }
    close $out or die $!;
    $buf
}

sub capture_stdout (&) {
    capture_stdout_(@_)
}

# stupid COPY-PASTE

sub capture_stderr_ {
    my ($thunk) = @_;
    my $buf = "";
    open my $out, ">", \$buf or die $!;
    {
        # XX threadsafe or not?
        local *STDERR = $out;
        &$thunk();    # dropping results
    }
    close $out or die $!;
    $buf
}

sub capture_stderr (&) {
    capture_stderr_(@_)
}

sub with_output_to_file {
    @_ == 2 or fp_croak_arity 2;
    my ($file, $thunk) = @_;
    my $wantarray = wantarray;
    my @res;
    open my $out, ">", $file
        or fp_croak "with_output_to_file: open '$file': $!";
    binmode $out, ":encoding(UTF-8)"
        or fp_croak "with_output_to_file: binmode '$file': $!";
    {
        local *STDOUT = $out;
        if (defined $wantarray) {
            if ($wantarray) {
                @res = &$thunk();
            } else {
                @res = scalar &$thunk();
            }
        } else {
            &$thunk();
        }
    }
    close $out or fp_croak "with_output_to_file: close '$file': $!";
    $wantarray ? @res : $res[0]
}

1
