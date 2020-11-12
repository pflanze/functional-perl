#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Char - functions to handle individual characters

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl doesn't have a distinct data type for individual characters, any
string containing 1 character is considered to be a char by
FP::Char. (Creating references and blessing them for the sake of
type safety seemed excessive.)


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Char;
@ISA = "Exporter";
require Exporter;
@EXPORT      = qw();
@EXPORT_OK   = qw(is_char char_is_whitespace char_is_alphanumeric);
%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

sub is_char ($) {
    my ($v) = @_;
    defined $v and not(ref $v) and length($v) == 1
}

sub char_is_whitespace {
    $_[0] =~ /^[ \r\n\t]$/s
}

sub char_is_alphanumeric {
    $_[0] =~ /^[a-zA-Z0-9_]$/s
}

1

