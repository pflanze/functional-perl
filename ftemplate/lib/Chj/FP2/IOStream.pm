#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP2::IOStream

=head1 SYNOPSIS

 use Chj::FP2::IOStream ':all'; # xopendir_stream, xopendir_pathstream
 use Chj::FP2::Stream; # stream_map
 use Chj::FP2::Lazy; # Force
 use Chj::FP2::List ':all'; # car
 my $paths= stream_map sub { my ($item)= @_; "$base/$item" }, xopendir_stream $base;
 # which is the same as: my $paths= xopendir_pathstream $base;
 my $firstpath= car Force $paths;
 # etc.

=head1 DESCRIPTION

Lazy IO (well, input), by reading items lazily as stream items.

(It's arguable whether that is a good idea; Haskell uses different
approaches nowadays. But it's still a nice way to do things if you're
careful.)

=cut


package Chj::FP2::IOStream;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(xopendir_stream
	      xopendir_pathstream);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::FP2::Lazy;
use Chj::xopendir;
use Chj::FP2::List ':all';
use Chj::FP2::Stream 'stream_map', 'array2stream';
use Chj::FP::Array_sort;

sub _xopendir_stream ($) {
    my ($path)=@_;
    my $d= xopendir $path;
    my $next; $next= sub {
	Delay {
	    if (defined (my $item= $d->xnread)) {
		cons $item, &$next
	    } else {
		$d->xclose;
		undef $next;
		undef
	    }
	}
    };
    &$next
}

sub _xopendir_stream_sorted ($$) {
    my ($path,$cmp)=@_;
    my $d= xopendir $path;
    my $items= array_sort [$d->xnread], $cmp;
    $d->xclose;
    array2stream $items
}

sub xopendir_stream ($;$) {
    my ($path,$maybe_cmp)=@_;
    if ($maybe_cmp) {
	_xopendir_stream_sorted $path,$maybe_cmp;
    } else {
	_xopendir_stream $path;
    }
}

sub xopendir_pathstream ($;$) {
    my ($base,$maybe_cmp)=@_;
    stream_map sub {
	my ($item)= @_;
	"$base/$item"
    }, xopendir_stream $base,$maybe_cmp
}


1
