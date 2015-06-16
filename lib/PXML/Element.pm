#
# Copyright 2013-2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

PXML::Element - base class for PXML elements

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package PXML::Element;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::Stream qw(stream_mixed_flatten stream_map);
use FP::Hash qw($empty_hash);

# XX Depend on these? PXML::Serialize uses these, so any app that
# serializes PXML would require them anyway.
use FP::Lazy;
use FP::List;

use Chj::xIO qw(capture_stdout);
use Chj::xopen 'glob2fh';


use Chj::NamespaceCleanAbove;

# [ name, attributes, body ]

sub new {
    my $cl=shift;
    @_==3 or die "wrong number of arguments";
    bless [@_], $cl
}

sub name {
    $_[0][0]
}

sub maybe_attributes {
    $_[0][1]
}

# NOTE that $empty_hash gives exceptions for accesses to any field!
# (With the current implementation of locked / const hashes in perl.)
# `exists` works as expected though. But then, PXML (as all of FP) may
# move to restricted hashes and arrays everywhere anyway, so this
# should be consistent then.
sub attributes {
    $_[0][1] // $empty_hash
}

sub body {
    # could be undef, too, but then undef is the empty list when
    # interpreted as a FP::List, thus no need for the maybe_
    # prefix. -- XXX that's not true anymore, null is not undef anymore.
    $_[0][2]
}

sub maybe_attribute {
    @_==2 or die "wrong number of arguments";
    my $s=shift;
    my ($name)=@_;
    $$s[1] and $$s[1]{$name}
}

# functional setters (following the convention I've started to use of
# "trailing _set means functional, leading set_ means mutation"))

sub name_set {
    my $s=shift;
    @_==1 or die "wrong number of arguments";
    bless [ $_[0], $$s[1], $$s[2] ], ref $s
}

sub attributes_set {
    my $s=shift;
    @_==1 or die "wrong number of arguments";
    bless [ $$s[0], $_[0], $$s[2] ], ref $s
}

sub body_set {
    my $s=shift;
    @_==1 or die "wrong number of arguments";
    bless [ $$s[0], $$s[1], $_[0] ], ref $s
}


# functional updaters

sub name_update {
     my $s=shift;
     @_==1 or die "wrong number of arguments";
     my ($fn)=@_;
     bless [ &$fn($$s[0]), $$s[1], $$s[2] ], ref $s
}

sub attributes_update {
     my $s=shift;
     @_==1 or die "wrong number of arguments";
     my ($fn)=@_;
     bless [ $$s[0], &$fn($$s[1]), $$s[2] ], ref $s
}

sub body_update {
     my $s=shift;
     @_==1 or die "wrong number of arguments";
     my ($fn)=@_;
     bless [ $$s[0], $$s[1], &$fn($$s[2]) ], ref $s
}


# mapping

sub body_map {
    my $s=shift;
    @_==1 or die "wrong number of arguments";
    my ($fn)=@_;
    $s->body_update (sub { stream_map $fn, stream_mixed_flatten $_[0] })
}


# "body text", a string, dropping tags; not having knowledge about
# which XML tags have 'relevant body text', this returns all of it.

# XX ugly: this is replicating part of the serializer. But don't want
# to touch the code there... so, here goes. Really, better languages
# have been created to write code in.


sub _text {
    my ($v)=@_;
    if (defined $v) {
	if (ref $v)  {
	    if (UNIVERSAL::isa ($v, "PXML::Element")) {
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
	    } elsif (is_pair $v) {
		my ($a,$v2)= $v->car_and_cdr;
		_text ($a) . _text ($v2);
	    } elsif (is_promise $v) {
		_text (force $v);
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


# only for debugging? Doesn't emit XML/XHTML prologues!  Also, ugly
# monkey-access to PXML::Serialize. Circular dependency, too.

sub string {
    my $s=shift;
    require PXML::Serialize;
    capture_stdout {
	PXML::Serialize::pxml_print_fragment_fast
	    ($s, Chj::xopen::glob2fh(*STDOUT));
    }
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


_END_
