#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::FP::Predicates

=head1 SYNOPSIS

=head1 DESCRIPTION

Useful as predicates for Chj::Struct field definitions.

=cut


package Chj::FP::Predicates;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	      stringP
	      natural0P
	      naturalP
	      boolean01P
	      booleanP
	      hashP
	      arrayP
	      procedureP
	      class_nameP
	      instance_ofP
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub stringP ($) {
    not ref ($_[0]) # relax?
}

sub natural0P ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^\d+\z/
}

sub naturalP ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^\d+\z/ and $_[0]
}

# strictly 0 or 1
sub boolean01P ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^[01]\z/
}

# undef, 0, "", or 1
sub booleanP ($) {
    not ref ($_[0]) # relax?
      and (! $_[0]
	   or
	   $_[0] eq "1");
}


sub hashP ($) {
    defined $_[0] and ref ($_[0]) eq "HASH"
}

sub arrayP ($) {
    defined $_[0] and ref ($_[0]) eq "ARRAY"
}

sub procedureP ($) {
    defined $_[0] and ref ($_[0]) eq "CODE"
}


my $classpart_re= qr/\w+/;

sub class_nameP ($) {
    my ($v)= @_;
    not ref ($v) and $v=~ /^(?:${classpart_re}::)*$classpart_re\z/;
}

sub instance_ofP ($) {
    my ($cl)=@_;
    class_nameP $cl or die "need class name string, got: $cl";
    sub ($) {
	UNIVERSAL::isa ($_[0], $cl);
    }
}


1
