#
# Copyright (c) 2004-2018 Christian Jaeger, copying@christianjaeger.ch
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

    is with_maxlen(9, sub { singlequote "Darc's place" }),
       "'Darc\\'s...'";


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

=head1 NOTE

This is alpha software! Read the package README.

=cut


package Chj::singlequote;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(singlequote);
@EXPORT_OK=qw(singlequote_sh singlequote_many many with_maxlen
              possibly_singlequote_sh singlequote_sh_many
              quote_javascript
              quote_C _quote_C
            );
# importing 'many' is probably not a good idea (depreciated)
%EXPORT_TAGS=(all=>[@EXPORT, @EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $maybe_maxlen;

sub with_maxlen ($&) {
    local $maybe_maxlen= $_[0];
    &{$_[1]}()
}


# Perl style:

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
*Chj::singlequote= \&singlequote;

sub many {
    my @strs= map {
        my $str;
        if (eval { $str= singlequote($_); 1 }) {
            $str
        } else {
            my $e= "$@";
            $e=~ s/\n.*//s;
            "<stringification error: $e>"
        }
    } @_;
    if (wantarray) {
        @strs
    } else {
        join ", ", @strs
    }
}
*singlequote_many= \&many;


# Shell (Bash) style:

sub singlequote_sh($ ;$ ) {
    my ($str,$alternative)=@_;
    if (defined $str) {
        $str=~ s/\'/'\\\''/sg;
        "'$str'"
    } else {
        defined($alternative)? $alternative:"undef"
    }
}
*Chj::singlequote_sh= \&singlequote_sh;

# don't quote bare words or simply formatted paths that don't need to
# be quoted
sub possibly_singlequote_sh ($) {
    my ($str)=@_;
    if ($str=~ m{^[\w/.-]+\z}) {
        $str
    } else {
        singlequote_sh $str
    }
}

sub singlequote_sh_many {
    join " ", map { possibly_singlequote_sh $_ } @_
}


sub quote_javascript ($) {
    my ($str)=@_;
    #require JSON::MaybeXS;
    #JSON->new->allow_nonref(1)->encode($str)

    # this doesn't turn special characters into backslash sequences
    #$str=~ s|\\|\\\\|sg;
    #$str=~ s|\"|\\\"|sg;
    #'"'.$str.'"'

    # <mst> if you're obsessed with avoiding dependencies, just use
    #       JSON::PP directly and suck up the terrible performance
    require JSON::PP;
    JSON::PP->new->allow_nonref(1)->encode($str)

    # <mst> note that JSON::MaybeXS is trivial and fatpacks fine
    # <mst> intentionally
}

sub _quote_C($) {
    my ($str)=@_;
    $str=~ s{(.)}{
        my $c=$1;
        my $i= ord $c;
        # https://en.wikipedia.org/wiki/Ascii
        ($i >= 32 and $i < 127) ?
          ( $c eq '"' ? "\\\"" :
            $c )
          :
          ( $c eq "\n" ? "\\n" :
            $c eq "\r" ? "\\r" :
            $c eq "\t" ? "\\t" :
            sprintf "\\%o", $i )
    }sge;
    $str
}

sub quote_C($){
    my ($str)=@_;
    '"'._quote_C($str).'"'
}


1
