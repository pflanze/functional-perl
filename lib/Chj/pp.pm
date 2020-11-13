#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::pp -- pretty printing as a debugging help

=head1 SYNOPSIS

    use Chj::pp;

    print pp (1/2) + 1, "\n"; # prints "0.5\n" to stderr then "1.5\n" to stdout

    print pp_ ("x", 1/2) + 1, "\n"; # prints "x: 0.5\n" to stderr then see above

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::pp;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT      = qw(pp pp_);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use Data::Dumper;
use Chj::TerseDumper;

sub Dump {
    @_ > 1 ? Dumper(@_) : TerseDumper(@_)
}

sub pp {
    print STDERR Dump(@_);
    wantarray ? @_ : $_[-1]
}

sub pp_ {
    my $msg = shift;
    print STDERR "$msg:", (@_ > 1 ? "\n" : " "), Dump(@_);
    wantarray ? @_ : $_[-1]
}

1
