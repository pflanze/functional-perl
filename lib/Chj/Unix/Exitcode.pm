# Sat Aug  4 09:38:07 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Exitcode

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Unix::Exitcode;

use strict;

use Chj::Unix::Signal;

use Class::Array -fields=>
  -publica=>
  'code',
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Code])=@_;
    $s
}

sub as_string {
    my $s=shift;
    my $code= $$s[Code];
    if ($code < 256) {
	"signal $code (".Chj::Unix::Signal->new($code)->as_string.")"
    } else {
	if (($code & 255) == 0) {
	    "exit value ".($code >> 8)
	} else {
	    warn "does this ever happen?";
	    "both exit value and signal ($code)"
	}
    }
}

end Class::Array;
