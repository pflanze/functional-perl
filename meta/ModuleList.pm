#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

ModuleList

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package ModuleList;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(modulenamelist modulepathlist);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';


use Chj::xopen 'xopen_read';

our $moduleandpathlist; # [[ name, path ] ...]

sub moduleandpathlist {
    $moduleandpathlist //= do {
	my $f = xopen_read "MANIFEST";
	my @m;
	local $_;
	while (<$f>) {
	    chomp;
	    my $path= $_;
	    next unless s/\.pm$//;
	    s|^(lib\|meta\|htmlgen)/|| or die "";
	    s|/|::|sg;
	    push @m, [$_, $path]
	}
	$f->xclose;
	\@m
    }
}

sub modulenamelist {
    [ map { $$_[0] } @{moduleandpathlist()} ]
}

sub modulepathlist {
    [ map { $$_[1] } @{moduleandpathlist()} ]
}

1
