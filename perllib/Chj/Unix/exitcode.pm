# Sat Aug  4 09:54:48 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::exitcode

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::exitcode;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(exitcode);
@EXPORT_OK=qw(exitcode);
%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Chj::Unix::Exitcode;

sub exitcode ( $ ) {
    my ($code)=@_;
    Chj::Unix::Exitcode->new($code)->as_string;
}

*Chj::Unix::exitcode= \&exitcode;

1
