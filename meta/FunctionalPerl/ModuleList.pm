#
# Copyright (c) 2015-2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::ModuleList

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::ModuleList;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(modulenamelist modulepathlist);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Chj::xopen 'xopen_read';

our $modulenameandpathlist;    # [[ name, path ] ...]

sub modulenameandpathlist {
    $modulenameandpathlist //= do {
        my $f = xopen_read "MANIFEST";
        my @m;
        local $_;
        while (<$f>) {         ## no critic, $_ is localized
            chomp;
            my $path = $_;
            next unless s/\.pm$//;
            s|^(lib\|meta\|htmlgen)/|| or die "no match: $_";
            s|/|::|sg;
            push @m, [$_, $path]
        }
        $f->xclose;
        \@m
    }
}

sub modulenamelist {
    [map { $$_[0] } @{ modulenameandpathlist() }]
}

sub modulepathlist {
    [map { $$_[1] } @{ modulenameandpathlist() }]
}

1
