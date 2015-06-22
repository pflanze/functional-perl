#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
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
	    s|^(lib\|meta)/|| or die;
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
