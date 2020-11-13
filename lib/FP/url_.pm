#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
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
    my $u = url_ path => "index.html", fragment => "foo#bar";
    # $u is an URI object
    is "$u", 'index.html#foo%23bar';

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::url_;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(url_);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);


use URI;

our @keys = qw(scheme path fragment);

our %keys = map { $_ => $_ } @keys;

sub url_ {
    my $u = new URI;
    while (@_) {
        my $k = shift;
        @_ or die "url_: uneven number of arguments";
        my $v = shift;
        my $m = $keys{$k} // die "url_: unknown key '$k'";
        $u->$m($v);
    }
    $u
}

1
