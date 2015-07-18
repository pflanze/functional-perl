#
# Copyright (c) 2004-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::singlequote

=head1 SYNOPSIS

 use Chj::singlequote qw(singlequote singlequote_many with_maxlen);

 with_maxlen 9, sub { singlequote "Darc's place" } # => "'Darc\\'s...'"

=head1 DESCRIPTION

Turn strings to quoted strings.

=over 4

=item singlequote ($str, $maybe_alternative)

Perl style quoting.

If $maybe_alternative is not given, uses the string "undef" for the
undef value.

=item singlequote_sh ($str, $maybe_alternative)

Shell style quoting.

Also currently uses the "undef" value as default alternative, although
not making much sense.

=item singlequote_many (@maybe_strs)

In list context returns each argument quoted. In scalar context, join
them with a comma inbetween.

Unlike the separate ones above, this captures exceptions during the
quoting process (stringification errors) and returns "<stringification
error: $@>" in that case.

=cut


package Chj::singlequote;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(singlequote);
@EXPORT_OK=qw(singlequote_sh singlequote_many many with_maxlen);
# importing 'many' is probably not a good idea (depreciated)
%EXPORT_TAGS=(all=>[@EXPORT, @EXPORT_OK]);

use strict;

our $maybe_maxlen;

sub with_maxlen ($&) {
    local $maybe_maxlen= $_[0];
    &{$_[1]}()
}


sub singlequote($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	if (defined $maybe_maxlen and length ($str) > $maybe_maxlen) {
	    $str= substr ($str, 0, $maybe_maxlen-3) . "...";
	}
	$str=~ s/\'/\\\'/sg;
	# avoid newlines (and more?), try to follow the Carp::confess
	# format, if maxlen is given:
	$str=~ s/([\t\n\r])/sprintf ('\\x{%x}', ord $1)/sge
	  if defined $maybe_maxlen;
	"'$str'"
    } else {
	defined($alternative)? $alternative:"undef"
    }
}
sub singlequote_sh($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
	$str=~ s/\'/'\\\''/sg;
	"'$str'"
    } else {
	defined($alternative)? $alternative:"undef"
    }
}

*Chj::singlequote= \&singlequote;
*Chj::singlequote_sh= \&singlequote_sh;

sub many {
    my @strs= map {
	my $str;
	if (eval { $str= singlequote($_); 1 }) {
	    $str
	} else {
	    "<stringification error: $@>"
	}
    } @_;
    if (wantarray) {
	@strs
    } else {
	join ", ", @strs
    }
}
*singlequote_many= \&many;


1
