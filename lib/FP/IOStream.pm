#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::IOStream

=head1 SYNOPSIS

 use FP::IOStream ':all'; # xopendir_stream, xopendir_pathstream
 use FP::Stream; # stream_map
 use FP::List ':all'; # first
 my $paths= stream_map sub { my ($item)= @_; "$base/$item" },
                       xopendir_stream $base;
 # which is the same as: my $paths= xopendir_pathstream $base;
 my $firstpath= first $paths;
 # ...

=head1 DESCRIPTION

Lazy IO (well, input), by reading items lazily as stream items.

(It's arguable whether that is a good idea; Haskell uses different
approaches nowadays. But it's still a nice way to do things if you're
careful.)

=cut


package FP::IOStream;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(fh_to_stream
	      xopendir_stream
	      xopendir_pathstream
	      xfile_lines
	      fh_to_chunks);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Lazy;
use Chj::xopendir;
use FP::List ':all';
use FP::Stream 'stream_map', 'array_to_stream', 'Weakened';
use FP::Array_sort;
use FP::Ops 'the_method';

sub _xopendir_stream ($) {
    my ($path)=@_;
    my $d= xopendir $path;
    my $next; $next= sub {
	my $next=$next;
	lazy {
	    if (defined (my $item= $d->xnread)) {
		cons $item, &$next
	    } else {
		$d->xclose;
		null
	    }
	}
    };
    &{Weakened $next}
}

sub _xopendir_stream_sorted ($$) {
    my ($path,$cmp)=@_;
    my $d= xopendir $path;
    my $items= array_sort [$d->xnread], $cmp;
    $d->xclose;
    array_to_stream $items
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



sub fh_to_stream ($$$) {
    my ($fh, $read, $close)=@_;
    my $next; $next= sub {
	my $next=$next;
	lazy {
	    if (defined (my $item= &$read($fh))) {
		cons $item, &$next
	    } else {
		&$close ($fh);
		null
	    }
	}
    };
    &{Weakened $next}
}

# And (all?, no, can't proxy 'xopen' for both in and out) some of the
# Chj::xopen functions:

use Chj::xopen qw(
	      xopen_read
	      xopen_write
	      xopen_append
	      xopen_update);

sub make_open_stream {
    my ($open,$read,$maybe_close)=@_;
    my $close= $maybe_close // the_method ("xclose");
    sub ($) {
	fh_to_stream(scalar &$open(@_),
		  $read,
		  $close)
    }
}

sub xfile_lines ($);
*xfile_lines=
  make_open_stream(\&xopen_read,
		   the_method ("xreadline"));



# read filehandle in chunks, although the chunk size, even of the
# chunks before the last one, is only guaranteed to be non-zero, not
# bufiz (since only xsysreadcompletely would guarantee to fill size,
# but would die on mid-chunk EOF)

sub fh_to_chunks ($$) {
    my ($fh,$bufsiz)= @_;
    fh_to_stream ($fh,
	       sub {
		   my $buf;
		   my $n= $fh->xsysread($buf, $bufsiz);
		   $n == 0 ? undef : $buf
	       },
	       the_method("xclose"));
}


1
