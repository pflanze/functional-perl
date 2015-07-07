#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::url_

=head1 SYNOPSIS

 use FP::url_;
 my $u= url_ path=> "index.html", fragment=> "foo#bar";
 # $u is an URI object
 "$u" # 'index.html#foo%23bar'

=head1 DESCRIPTION


=cut


package FP::url_;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(url_);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use URI;

our @keys=
  qw(scheme path fragment);

our %keys=
  map { $_=> $_ } @keys;

sub url_ {
    my $u= new URI;
    while (@_) {
	my $k=shift;
	@_ or die "url_: uneven number of arguments";
	my $v=shift;
	my $m= $keys{$k} // die "url_: unknown key '$k'";
	$u->$m($v);
    }
    $u
}


1
