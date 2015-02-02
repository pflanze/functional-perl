#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Text::CSV - functional interface to Text::CSV

=head1 SYNOPSIS

 use Chj::FP::Text::CSV qw(csv_line_xparser fh2csvstream xopen_csv_stream);

 my $csvparams= +{sep_char=> ";", eol=> "\n"};
 # $csvparams and any of its entries are optional,
 #  defaults are taken from $Chj::FP::Text::CSV::defaults

 my $p= csv_line_xparser $csvparams;
 my @vals= &$p("1;2;3;4\n");

 my $stream= fh2csvstream($somefilehandle, $csvparams);
 # or
 my $stream= xopen_csv_stream($somepath, $csvparams);

 # then
 use Chj::FP::Stream ":all";
 my $stream2= stream_map sub {
     my ($row)=@_;
     #...
 }, $stream;
 # etc.

=head1 DESCRIPTION


=cut


package Chj::FP::Text::CSV;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
		 new_csv_instance
		 csv_line_xparser
		 fh2csvstream
		 xopen_csv_stream
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

use Chj::FP::List ":all";
use Chj::FP::Lazy ":all";
use Scalar::Util 'weaken';
use Text::CSV;
use Chj::FP::HashSet 'hashset_union';
use Chj::xopen 'xopen_read';

our $defaults=
  +{
    binary => 1,
    sep_char=> "\t",
    eol=> "\r\n",
   };

sub params ($) {
    my ($maybe_params)=@_;
    defined $maybe_params ? hashset_union($maybe_params, $defaults)
      : $defaults
}

sub new_csv_instance (;$) {
    my ($maybe_params)=@_;
    Text::CSV->new(params $maybe_params)
}

sub csv_line_xparser (;$) {
    my ($maybe_params)=@_;
    my $csv= new_csv_instance $maybe_params;
    sub ($) {
	my ($line)=@_;
	$csv->parse($line)
	  or die "CSV parsing failure"; # XX how to get error message from Text::CSV?
	$csv->fields
    }
}


sub fh2csvstream ($;$) {
    my ($in, $maybe_params)=@_;
    my $csv= new_csv_instance ($maybe_params);
    my $next; $next= sub {
	Delay {
	    if (my $row= $csv->getline ($in)) {
		# XX error checks?
		cons $row, &$next;
	    } else {
		$in->xclose;
		null
	    }
	}
    };
    my $_next=$next; weaken $next;
    &$_next
}

sub xopen_csv_stream ($;$) {
    my ($path, $maybe_params)=@_;
    my $in= xopen_read $path;
    binmode($in, ":encoding(utf-8)") or die;
    fh2csvstream $in, $maybe_params
}


1
