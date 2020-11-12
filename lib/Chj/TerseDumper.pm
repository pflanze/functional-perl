#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::TerseDumper

=head1 SYNOPSIS

    use Chj::TerseDumper;
    my $foo = +{ foo => 1, bar => 10, baz => -1 };
    is terseDumper($foo), "XXX";
    is TerseDumper($foo), "XXX";

=head1 DESCRIPTION

Runs Data::Dumper's Dumper with $Data::Dumper::Terse set to 1.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::TerseDumper;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw(TerseDumper terseDumper);
@EXPORT_OK   = qw(UnsortedTerseDumper);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use Data::Dumper;

sub UnsortedTerseDumper {
    local $Data::Dumper::Terse = 1;
    Dumper(@_)
}

sub TerseDumper {
    local $Data::Dumper::Sortkeys = 1;
    UnsortedTerseDumper(@_)
}

sub terseDumper {
    my $str = TerseDumper(@_);
    chomp $str;
    $str
}

1
