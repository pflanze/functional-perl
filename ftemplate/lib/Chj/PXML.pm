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

use strict;

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
