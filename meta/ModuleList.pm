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
@EXPORT=qw(modulelist);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';


use Chj::xopen 'xopen_read';

our $modulelist;

sub modulelist {
    $modulelist //= do {
	my $f = xopen_read "MANIFEST";
	my @m;
	while (<$f>) {
	    chomp;
	    next unless s/\.pm$//;
	    s|^(lib\|meta)/|| or die;
	    s|/|::|sg;
	    push @m, $_
	}
	$f->xclose;
	\@m
    }
}

1
