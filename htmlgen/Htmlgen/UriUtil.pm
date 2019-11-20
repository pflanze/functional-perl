#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::UriUtil

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the package README.

=cut


package Htmlgen::UriUtil;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(uri_add URI_is_internal);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

use Chj::TEST;
use URI;

fun uri_add ($base,$rel) {
    URI->new($rel)->abs(URI->new($base)).""
}

TEST{uri_add "http://bar.com/baz/", "/zoo#hm"} "http://bar.com/zoo#hm";
TEST{uri_add "http://bar.com/baz/", "zoo"} "http://bar.com/baz/zoo";
TEST{uri_add "http://bar.com/baz", "zoo"} "http://bar.com/zoo";
TEST{uri_add "http://bar.com/baz/#ax", "#bx"} "http://bar.com/baz/#bx";


# avoid monkey-patching by prefixing instead
method URI_is_internal () {
    not defined $self->scheme
}


1
