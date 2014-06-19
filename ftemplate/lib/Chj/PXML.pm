#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::PXML

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::PXML;

use strict; use warnings FATAL => 'uninitialized';

# [ name, attributes, body ]

sub new {
    my $cl=shift;
    @_==3 or die;
    bless [@_], $cl
}

sub name {
    $_[0][0]
}
sub maybe_attributes {
    $_[0][1]
}
sub body {
    # could be undef, too, but then undef is the empty list when
    # interpreted as a Chj::FP2::List, thus no need for the maybe_
    # prefix.
    $_[0][2]
}

sub maybe_attribute {
    @_==2 or die;
    my $s=shift;
    my ($name)=@_;
    $$s[1] and $$s[1]{$name}
}

# functional setters
sub set_attributes {
    my $s=shift;
    @_==1 or die;
    bless [ $$s[0], $_[0], $$s[2] ], ref $s
}

sub set_body {
    my $s=shift;
    @_==1 or die;
    bless [ $$s[0], $$s[1], $_[0] ], ref $s
}

# or, follow the convention I've started to use of "tailing _set means
# functional" (versus leading set_ normally meaning mutation):
*body_set= *set_body;
*attributes_set= *set_attributes;

# functional updaters

sub attributes_update {
     my $s=shift;
     @_==1 or die;
     my ($fn)=@_;
     bless [ $$s[0], &$fn($$s[1]), $$s[2] ], ref $s
 }

sub body_update {
     my $s=shift;
     @_==1 or die;
     my ($fn)=@_;
     bless [ $$s[0], $$s[1], &$fn($$s[2]) ], ref $s
}


# "body text", a string, dropping tags; not having knowledge about
# which XML tags have 'relevant body text', this returns all of it.

# XX ugly: this is replicating part of the serializer. But don't want
# to touch the code there... so, here goes. Really, better languages
# have been created to write code in.

# XX Depend on these? Chj::PXML::Serialize uses these, so any app that
# serializes PXML would require them anyway.
use Chj::FP2::Lazy;
use Chj::FP2::List;

sub _text {
    my ($v)=@_;
    if (defined $v) {
	if (ref $v)  {
	    if (UNIVERSAL::isa ($v, "Chj::PXML")) {
		$v->text
	    } elsif (UNIVERSAL::isa ($v, "ARRAY")) {
		join("",
		     map {
			 _text ($_)
		     } @$v);
	    } elsif (UNIVERSAL::isa ($v, "CODE")) {
		# correct? XX why does A(string2stream("You're
		# great."))->text trigger this case?
		_text (&$v ());
	    } elsif (pairP $v) {
		my ($a,$v2)= $v->carcdr;
		_text ($a) . _text ($v2);
	    } elsif (promiseP $v) {
		_text (Force $v);
	    } else {
		die "don't know how to get text of: $v";
	    }
	} else {
	    $v
	}
    } else {
	""
    }
}

sub text {
    my $s=shift;
    join("",
	 map {
	     _text ($_)
	 } @{$s->body});
}


# XML does not distinguish between void elements and non-void ones in
# its syntactical representation; whether an element is printed in
# self-closing representation is orthogonal and can rely simply on
# whether the content of the particular element ('at runtime') is
# empty.

sub require_printing_nonvoid_elements_nonselfreferential  {
    0
}

#sub void_element_h {
#    undef
#}

1
