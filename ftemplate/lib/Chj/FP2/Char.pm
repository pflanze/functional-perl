#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP2::Char - functions to handle individual characters

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl doesn't have a distinct data type for individual characters, any
string containing 1 character is considered to be a char by
Chj::FP2::Char. (Creating references and blessing them for the sake of
type safety seemed excessive.)


=cut


package Chj::FP2::Char;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(charP char_whitespaceP char_alphanumericP);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

sub charP ($) {
    my ($v)=@_;
    defined $v and not (ref $v) and length($v)==1
}

sub char_whitespaceP {
    $_[0]=~ /^[ \r\n\t]$/s
}

sub char_alphanumericP {
    $_[0]=~ /^[a-zA-Z0-9_]$/s
}


1

