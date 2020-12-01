#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::xIOUtil - exception-throwing I/O utilities

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xIOUtil;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(xgetfile_utf8 xputfile_utf8 xcopyfile_utf8 xprint_object
    xcopyfile);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::xopen ":all";

# ^ well, this voids the purpose of Chj::xIO (to avoid Chj::IO::*)
use FP::Lazy;
use FP::List;
use Chj::xperlfunc qw(xxsystem_safe xprint xgetfile_utf8);
use FP::Carp;

# print, not write, i.e. flatten nested structures out, but don't
# print parens for lists etc., just print the contained basic types.
sub xprint_object {
    @_ == 2 or fp_croak_arity 2;
    my ($fh, $v) = @_;
    if (ref $v) {
        if (ref($v) eq "ARRAY") {
            xprint_object($fh, $_) for @$v;
        } elsif (is_pair $v) {
            xprint_object($fh, car $v);
            xprint_object($fh, cdr $v);
        } elsif (is_promise $v) {
            xprint_object($fh, force $v)
        } else {
            die "don't know how to print a " . ref($v) . " ('$v')";
        }
    } else {
        xprint $fh, $v
    }
}

sub xputfile_utf8 {
    @_ == 2 or fp_croak_arity 2;
    my ($path, $str) = @_;
    my $out = xopen_write($path);
    binmode $out, ":encoding(UTF-8)" or die "binmode";
    xprint_object($out, $str);
    $out->xclose;
}

sub xcopyfile_utf8 {
    @_ == 2 or fp_croak_arity 2;
    my ($src, $dest) = @_;
    xputfile_utf8($dest, xgetfile_utf8($src));
}

sub xcopyfile {
    @_ == 2 or fp_croak_arity 2;
    my ($src, $dest) = @_;

    # yes, giving up here. XX write something else or just use
    # Filecopy or whatever from CPAN.
    xxsystem_safe "cp", "-a", "--", $src, $dest
}

1
