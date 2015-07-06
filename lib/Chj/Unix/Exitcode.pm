#
# Copyright (c) 2007 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

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
