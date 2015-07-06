#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Char - functions to handle individual characters

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl doesn't have a distinct data type for individual characters, any
string containing 1 character is considered to be a char by
FP::Char. (Creating references and blessing them for the sake of
type safety seemed excessive.)


=cut


package FP::Char;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(is_char char_is_whitespace char_is_alphanumeric);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

sub is_char ($) {
    my ($v)=@_;
    defined $v and not (ref $v) and length($v)==1
}

sub char_is_whitespace {
    $_[0]=~ /^[ \r\n\t]$/s
}

sub char_is_alphanumeric {
    $_[0]=~ /^[a-zA-Z0-9_]$/s
}


1

