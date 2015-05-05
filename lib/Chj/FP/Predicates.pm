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
	      is_string
	      is_nonnullstring
	      is_natural0
	      is_natural
	      is_boolean01
	      is_boolean
	      is_hash
	      is_array
	      is_procedure
	      is_class_name
	      is_instance_of

	      is_filename

	      maybe
	 );
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

sub is_string ($) {
    not ref ($_[0]) # relax?
}

sub is_nonnullstring ($) {
    not ref ($_[0]) # relax?
      and length $_[0]
}

sub is_natural0 ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^\d+\z/
}

sub is_natural ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^\d+\z/ and $_[0]
}

# strictly 0 or 1
sub is_boolean01 ($) {
    not ref ($_[0]) # relax?
      and $_[0]=~ /^[01]\z/
}

# undef, 0, "", or 1
sub is_boolean ($) {
    not ref ($_[0]) # relax?
      and (! $_[0]
	   or
	   $_[0] eq "1");
}


sub is_hash ($) {
    defined $_[0] and ref ($_[0]) eq "HASH"
}

sub is_array ($) {
    defined $_[0] and ref ($_[0]) eq "ARRAY"
}

sub is_procedure ($) {
    defined $_[0] and ref ($_[0]) eq "CODE"
}


my $classpart_re= qr/\w+/;

sub is_class_name ($) {
    my ($v)= @_;
    not ref ($v) and $v=~ /^(?:${classpart_re}::)*$classpart_re\z/;
}

sub is_instance_of ($) {
    my ($cl)=@_;
    is_class_name $cl or die "need class name string, got: $cl";
    sub ($) {
	UNIVERSAL::isa ($_[0], $cl);
    }
}


# should probably be in a filesystem lib instead?
sub is_filename ($) {
    my ($v)=@_;
    (is_nonnullstring ($v)
     and !($v=~ m|/|)
     and !($v eq ".")
     and !($v eq ".."))
}

sub maybe ($) {
    my ($pred)=@_;
    sub ($) {
	my ($v)=@_;
	defined $v ? &$pred ($v) : 1
    }
}

1
