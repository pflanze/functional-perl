#
# Copyright (c) 2013-2015 Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

PXML::Tags

=head1 SYNOPSIS

 use PXML::Tags qw(records
     protocol-version
     record);
 my $xml= RECORDS(PROTOCOL_VERSION("1.0"), RECORD(...));

=head1 DESCRIPTION

Creates tag wrappers that return PXML elements. The names of the
wrappers are all uppercase, and "-" is replaced with "_".

=cut


package PXML::Tags;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use PXML::Element;

sub import {
    my $caller=caller;
    for my $name (@_) {
	my $fname= uc $name;
	$fname=~ s/-/_/sg;
	my $fqname= "${caller}::$fname";
	no strict 'refs';
	*$fqname= sub {
	    my $atts= ref($_[0]) eq "HASH" ? shift : undef;
	    PXML::Element->new($name, $atts, [@_]);
	};
    }
    1
}

1
