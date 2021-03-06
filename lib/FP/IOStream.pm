#
# Copyright (c) 2014-2021 Christian Jaeger, copying@christianjaeger.ch
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
    my $paths = stream_map sub { my ($item) = @_; "$base/$item" },
                          xdirectory_items $base;
    # which is the same as: my $paths = xdirectory_paths $base;
    my $firstpath = first $paths;
    # ...

=head1 DESCRIPTION

Lazy IO (well, input), by reading items lazily as stream items.

(It's arguable whether that is a good idea; Haskell uses different
approaches nowadays. But it's still a nice way to do things if you're
careful.)

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::IOStream;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(maybeIO_to_stream
    fh_to_stream
    perhaps_directory_items
    perhaps_directory_paths
    xdirectory_items
    xdirectory_paths
    xfile_lines xfile_lines0 xfile_lines0chop xfile_lines_chomp
    xfile_chars
    fh_to_lines
    fh_to_chunks
    timestream
    xstream_print
    xstream_to_file
    xfile_replace_lines
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Lazy;
use Chj::xopendir qw(perhaps_opendir);
use FP::List ':all';
use FP::Stream qw(stream_map weaken Weakened);
use FP::PureArray qw(array_to_purearray);
use FP::Array_sort;
use FP::Ops 'the_method';
use Carp;
use Chj::singlequote ":all";
use Chj::xopen qw(
    xopen_read
    xopen_write
    xopen_append
    xopen_update
    possibly_fh_to_fh
    glob_to_fh
);
use Chj::xtmpfile qw(xtmpfile);
use FP::Carp;

# XX use this for the definitions further below instead of re-coding
# it each time?
sub maybeIO_to_stream {
    my ($maybeIO, $maybe_close) = @_;
    my $next;
    $next = sub {
        my $next = $next;
        lazyT {
            if (defined(my $v = &$maybeIO())) {
                cons($v, &$next)
            } else {
                if (defined $maybe_close) {
                    &$maybe_close()
                }
                null
            }
        }
        "FP::List::List"
    };
    &{ Weakened $next}
}

sub _perhaps_opendir_stream {
    @_ == 1 or fp_croak_arity 1;
    my ($path) = @_;
    if (my ($d) = perhaps_opendir $path) {
        my $next;
        $next = sub {
            my $next = $next;
            lazyT {
                if (defined(my $item = $d->xnread)) {
                    cons $item, &$next
                } else {
                    $d->xclose;
                    null
                }
            }
            "FP::List::List"
        };
        &{ Weakened $next}
    } else {
        ()
    }
}

sub _perhaps_opendir_stream_sorted {
    @_ == 2 or fp_croak_arity 2;
    my ($path, $cmp) = @_;
    if (my ($d) = perhaps_opendir $path) {
        my $items = array_sort [$d->xnread], $cmp;
        $d->xclose;
        array_to_purearray $items
    } else {
        ()
    }
}

sub perhaps_directory_items {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($path, $maybe_cmp) = @_;
    if ($maybe_cmp) {
        _perhaps_opendir_stream_sorted $path, $maybe_cmp;
    } else {
        _perhaps_opendir_stream $path;
    }
}

sub perhaps_directory_paths {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($base, $maybe_cmp) = @_;
    $base .= "/" unless $base =~ /\/\z/;
    if (my ($s) = perhaps_directory_items $base, $maybe_cmp) {
        $s->map(
            sub {
                my ($item) = @_;
                "$base$item"
            }
        )
    } else {
        ()
    }
}

sub xdirectory_items {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($path, $maybe_cmp) = @_;
    if (my ($s) = perhaps_directory_items($path, $maybe_cmp)) {
        $s
    } else {
        croak "xdirectory_items(" . singlequote_many(@_) . "): $!";
    }
}

sub xdirectory_paths {
    @_ >= 1 and @_ <= 2 or fp_croak_arity "1-2";
    my ($path, $maybe_cmp) = @_;
    if (my ($s) = perhaps_directory_paths($path, $maybe_cmp)) {
        $s
    } else {
        croak "xdirectory_paths(" . singlequote_many(@_) . "): $!";
    }
}

sub fh_to_stream {
    @_ == 3 or fp_croak_arity 3;
    my ($fh, $read, $close) = @_;
    my $next;
    $next = sub {
        my $next = $next;
        lazyT {
            if (defined(my $item = &$read($fh))) {
                cons $item, &$next
            } else {
                &$close($fh);
                null
            }
        }
        "FP::List::List"
    };
    &{ Weakened $next}
}

# And (all?, no, can't proxy 'xopen' for both in and out) some of the
# Chj::xopen functions:

sub make_open_stream {
    my ($open, $read, $maybe_close) = @_;
    my $close = $maybe_close // the_method("xclose");
    sub {
        @_ == 1 or @_ == 2 or fp_croak_arity("1 or 2");
        my ($path, $maybe_encoding) = @_;
        my $fh = &$open($path);
        if ($maybe_encoding) {
            binmode($fh, ":encoding($maybe_encoding)")
                or croak "binmode for :encoding($maybe_encoding): $!";
        }
        fh_to_stream($fh, $read, $close)
    }
}

sub xfile_lines;
*xfile_lines = make_open_stream(\&xopen_read, the_method("xreadline"));

sub xfile_lines0;
*xfile_lines0 = make_open_stream(\&xopen_read, the_method("xreadline0"));

sub xfile_lines0chop;
*xfile_lines0chop
    = make_open_stream(\&xopen_read, the_method("xreadline0_chop"));

sub xfile_lines_chomp;
*xfile_lines_chomp
    = make_open_stream(\&xopen_read, the_method("xreadline_chomp"));

sub xfile_chars;
*xfile_chars = make_open_stream(\&xopen_read, the_method("xreadchar"));

# Clojure calls this line-seq
#  (http://clojure.github.io/clojure/clojure.core-api.html#clojure.core/line-seq)
sub fh_to_lines {
    @_ == 1 or fp_croak_arity 1;
    my ($fh) = @_;
    fh_to_stream(possibly_fh_to_fh($fh), the_method("xreadline"),
        the_method("xclose"))
}

# read filehandle in chunks, although the chunk size, even of the
# chunks before the last one, is only guaranteed to be non-zero, not
# bufiz (since only xsysreadcompletely would guarantee to fill size,
# but would die on mid-chunk EOF)

sub fh_to_chunks {
    @_ == 2 or fp_croak_arity 2;
    my ($fh, $bufsiz) = @_;
    fh_to_stream(
        possibly_fh_to_fh($fh),
        sub {
            my $buf;
            my $n = $fh->xsysread($buf, $bufsiz);
            $n == 0 ? undef : $buf
        },
        the_method("xclose")
    );
}

# A stream of floating-point unix timestamps representing the time
# when each cell is being forced. Optional argument in seconds
# (floating point) to sleep before returning the next element.

sub timestream {
    @_ >= 0 and @_ <= 1 or fp_croak_arity "0-1";
    my ($maybe_sleep) = @_;
    require Time::HiRes;
    my $lp;
    $lp = sub {
        lazyT {
            Time::HiRes::sleep($maybe_sleep) if $maybe_sleep;
            cons(Time::HiRes::time(), &$lp())
        }
        "FP::List::Pair"
    };
    Weakened($lp)->();
}

sub xstream_print {
    @_ == 1 or @_ == 2 or fp_croak_arity "1 or 2";
    my ($s, $maybe_fh) = @_;
    my $fh = $maybe_fh // glob_to_fh(*STDOUT);
    weaken $_[0];
    $s->for_each(
        sub {
            print $fh $_[0] or croak "xstream_print: writing to $fh: $!";
        }
    );
}

sub xstream_to_file {
    @_ == 2 or @_ == 3 or fp_croak_arity "2 or 3";
    my ($s, $path, $maybe_mode) = @_;
    my $out = xtmpfile $path;
    weaken $_[0];
    xstream_print($s, $out);
    $out->xclose;
    $out->xputback($maybe_mode);
}

# read and write back a file, passing its lines as a stream to the
# given function; written to temp file that's renamed into place upon
# successful completion.
sub xfile_replace_lines {
    @_ == 2 or fp_croak_arity 2;
    my ($path, $fn) = @_;
    xstream_to_file &$fn(xfile_lines $path), $path;
}

1
