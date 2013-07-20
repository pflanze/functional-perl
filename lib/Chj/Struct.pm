#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Struct

=head1 SYNOPSIS

 use Chj::Struct Bar=> ["a","b"]=> ["Foo"];
 # creates a constructor new that takes positional arguments and
 # copies them to a hash with the keys "a" and "b". Also, sets
 # @Bar::ISA to ("Foo"). [ ] around "Foo" are optional.
 {
   package Bar;
   # instead of use Chj::Struct Bar.. above, could use this:
   # use Chj::Struct ["a","b"]=> ["Foo"];
   sub sum {
      my $s=shift;
      $$s{a} + $$s{b}
   }
   _END_ # generate accessors for methods of given name which don't
         # exist yet *in either Bar or any super class*. (Does that
         # make sense?)
 }
 new Bar (1,2)-> sum #=> 3

=head1 DESCRIPTION

Simpler than Class::Struct. Ok?

=cut


package Chj::Struct;

use strict;
use Carp;

sub require_package {
    my ($package)=@_;
    no strict 'refs';
    if (not keys %{$package."::"}) {
	$package=~ s|::|/|g;
	$package.=".pm";
	require $package
    }
}

sub import {
    my $_importpackage= shift;
    return unless @_;
    my ($package, $fields, @isa);
    if (ref $_[0]) {
	($fields, @isa)= @_;
	$package= caller;
    } else {
	($package, $fields, @isa)= @_;
    }
    no strict 'refs';
    if (@isa) {
	require_package $_ for @isa;
	*{"${package}::ISA"}= (@isa==1 and ref($isa[0])) ? $isa[0] : \@isa;
    }
    *{"${package}::new"}= sub {
	my $class=shift;
	@_ <= @$fields
	  or croak "too many arguments to ${package}::new";
	my %s;
	for (my $i=0; $i< @_; $i++) {
	    $s{ $$fields[$i] }= $_[$i];
	}
	bless \%s, $class
    }
      if @$fields;
    *{"${package}::_END_"}= sub {
	for my $field (@$fields) {
	    if (not $package->can($field)) {
		*{"${package}::$field"}= sub {
		    my $s=shift;
		    $$s{$field}
		};
	    }
	}
	1 # make module load succeed at the same time.
    };
}


1
