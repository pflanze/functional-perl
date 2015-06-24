#
# Copyright 2004-2014 by Christian Jaeger, ch at christianjaeger . ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::singlequote

=head1 SYNOPSIS

 use Chj::singlequote qw(singlequote singlequote_many with_maxlen);

 with_maxlen 9, sub { singlequote "Darc's place" } # => "'Darc\\'s...'"

=head1 DESCRIPTION


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
    if (wantarray) {
	map { singlequote($_) } @_
    } else {
	join ", ", map { singlequote($_) } @_
    }
}
*singlequote_many= \&many;


use Chj::TEST;
TEST { with_maxlen 9, sub { singlequote "Darc's place" } }
  "'Darc\\'s...'";

1
