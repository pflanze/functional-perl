#
# Copyright (c) 2019-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::IsPerl

=head1 SYNOPSIS

    use Chj::IsPerl qw(is_perl_file);
    is is_perl_file(__FILE__), 1;

=head1 DESCRIPTION

Report whether a file is (primarily) holding Perl code.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::IsPerl;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter 'import';

our @EXPORT_OK = qw(
    is_perl_exe_shebang
    is_perl_module_path
    is_perl_script_path
    is_perl_module
    is_perl_exe
    is_perl_file
);

sub fh_looks_perlish {
    0    # don't go there, OK?
}

my $perl_re = qr(perl(?:5(?:\.\d+.*)?)?);

sub is_perl_exe_shebang {
    my ($path) = @_;
    open my $in, "<", $path or die "'$path': $!";
    my $head = <$in>;
    defined $head or die "'$path': $!";
    if (my ($exe, $rest) = $head =~ m!^#\!(\S+)\s+(.*)!s) {
        ($exe =~ m!(^|/)$perl_re\z!s or $rest =~ m!(^|\S+/)$perl_re(?:\s|\z)!s)
    } else {
        0
    }
}

sub is_perl_module_path {
    my ($path) = @_;
    scalar $path =~ m!\w\.pm\z!s
}

sub is_perl_script_path {
    my ($path) = @_;
    $path =~ m!\w\.pl\z!s or $path =~ m!(?:^|/)Makefile.PL\z!si
}

# And the main API:

sub is_perl_module {
    my ($path) = @_;
    is_perl_module_path $path
}

sub is_perl_exe {
    my ($path) = @_;
    is_perl_script_path $path or is_perl_exe_shebang $path
}

sub is_perl_file {
    my ($path) = @_;
    is_perl_module $path or is_perl_exe $path
}

1
