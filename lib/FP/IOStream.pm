#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::IOStream

=head1 SYNOPSIS

 use FP::IOStream ':all'; # xdirectory_items, xdirectory_paths
 use FP::Stream; # stream_map
 use FP::List ':all'; # first
 my $paths= stream_map sub { my ($item)= @_; "$base/$item" },
                       xdirectory_items $base;
 # which is the same as: my $paths= xdirectory_paths $base;
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
	      perhaps_directory_items
	      perhaps_directory_paths
	      xdirectory_items
	      xdirectory_paths
	      xfile_lines
	      fh_to_lines
	      fh_to_chunks
	      timestream);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Lazy;
use Chj::xopendir qw(perhaps_opendir);
use FP::List ':all';
use FP::Stream 'stream_map', 'Weakened';
use FP::PureArray qw(unsafe_array_to_purearray);
use FP::Array_sort;
use FP::Ops 'the_method';
use Carp;
use Chj::singlequote ":all";

sub _perhaps_opendir_stream ($) {
    my ($path)=@_;
    if (my ($d)= perhaps_opendir $path) {
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
    } else {
	()
    }
}

sub _perhaps_opendir_stream_sorted ($$) {
    my ($path,$cmp)=@_;
    if (my ($d)= perhaps_opendir $path) {
	my $items= array_sort [$d->xnread], $cmp;
	$d->xclose;
	unsafe_array_to_purearray $items
    } else {
	()
    }
}

sub perhaps_directory_items ($;$) {
    my ($path,$maybe_cmp)=@_;
    if ($maybe_cmp) {
	_perhaps_opendir_stream_sorted $path,$maybe_cmp;
    } else {
	_perhaps_opendir_stream $path;
    }
}

sub perhaps_directory_paths ($;$) {
    my ($base,$maybe_cmp)=@_;
    $base.= "/" unless $base=~ /\/\z/;
    if (my ($s)= perhaps_directory_items $base,$maybe_cmp) {
	stream_map sub {
	    my ($item)= @_;
	    "$base$item"
	}, $s
    } else {
	()
    }
}

sub xdirectory_items ($;$) {
    my ($path,$maybe_cmp)=@_;
    if (my ($s)= perhaps_directory_items ($path, $maybe_cmp)) {
	$s
    } else {
	croak "xdirectory_items(".singlequote_many(@_)."): $!";
    }
}

sub xdirectory_paths ($;$) {
    my ($path,$maybe_cmp)=@_;
    if (my ($s)= perhaps_directory_paths ($path, $maybe_cmp)) {
	$s
    } else {
	croak "xdirectory_paths(".singlequote_many(@_)."): $!";
    }
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
		     xopen_update
		     possibly_fh_to_fh
		);

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


# Clojure calls this line-seq
#  (http://clojure.github.io/clojure/clojure.core-api.html#clojure.core/line-seq)
sub fh_to_lines ($) {
    my ($fh)=@_;
    fh_to_stream (possibly_fh_to_fh($fh),
		  the_method ("xreadline"),
		  the_method ("xclose"))
}


# read filehandle in chunks, although the chunk size, even of the
# chunks before the last one, is only guaranteed to be non-zero, not
# bufiz (since only xsysreadcompletely would guarantee to fill size,
# but would die on mid-chunk EOF)

sub fh_to_chunks ($$) {
    my ($fh,$bufsiz)= @_;
    fh_to_stream (possibly_fh_to_fh($fh),
		  sub {
		      my $buf;
		      my $n= $fh->xsysread($buf, $bufsiz);
		      $n == 0 ? undef : $buf
		  },
		  the_method("xclose"));
}


# A stream of floating-point unix timestamps representing the time
# when each cell is being forced. Optional argument in seconds
# (floating point) to sleep before returning the next element.

sub timestream (;$) {
    my ($maybe_sleep)=@_;
    require Time::HiRes;
    my $lp; $lp= sub {
	lazy {
	    Time::HiRes::sleep ($maybe_sleep)
		if $maybe_sleep;
	    cons (Time::HiRes::time (), &$lp())
	}
    };
    Weakened ($lp)->();
}


1
