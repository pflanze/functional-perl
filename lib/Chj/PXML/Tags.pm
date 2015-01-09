#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::PXML::Tags

=head1 SYNOPSIS

 use Chj::PXML::Tags qw(records
     protocol-version
     record);
 my $xml= RECORDS(PROTOCOL_VERSION("1.0"), RECORD(...));

=head1 DESCRIPTION

Creates tag wrappers that return Chj::PXML elements. The names of the
wrappers are all uppercase, and "-" is replaced with "_".

=cut


package Chj::PXML::Tags;

use strict; use warnings FATAL => 'uninitialized';

use Chj::PXML ();

sub import {
    my $caller=caller;
    for my $name (@_) {
	my $fname= uc $name;
	$fname=~ s/-/_/sg;
	my $fqname= "${caller}::$fname";
	no strict 'refs';
	*$fqname= sub {
	    my $atts= ref($_[0]) eq "HASH" ? shift : undef;
	    Chj::PXML->new($name, $atts, [@_]);
	};
    }
    1
}

1
