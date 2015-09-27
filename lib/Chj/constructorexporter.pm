#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::constructorexporter

=head1 SYNOPSIS

 {
     package Foo;
     use Chj::constructorexporter;
     *import= constructorexporter new=> "Foo", new_from_string=> "foo";
     sub new { ... }
 }
 use Foo "foo", "foo"; # or ":all"; 'use Foo;' would not import anything
 foo("abc") # calls Foo->new_from_string("abc")
 Foo(1,2) # calls Foo->new(1,2)

 {
     package Bar;
     our @ISA="Foo";
 }
 use Bar "foo"; # this exports a different "foo"!
 foo("def") # calls Bar->new("def")


=head1 DESCRIPTION

This module might be evil: it helps writing OO modules that also
export functions. It only helps to export functions that are
constructors for the class in question, though, so its evilness might
be bounded.

Subclasses that inherit (don't override) the import method will export
constructors for the subclass those are imported from. That might be
sensible or pure evil, the creator of this module isn't sure yet. If
you don't like this, either override 'import' in the subclass, or ask
for this to be changed.

=cut


package Chj::constructorexporter;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(constructorexporter);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings FATAL => 'uninitialized';

sub constructorexporter {
    my %exportdecl= @_;
    sub {
	my $class=shift;
	my $package= caller;

	my $exportdecl= +{map {
	    my $methodname=$_;
	    my $exportname= $exportdecl{$methodname};
	    ($exportname=> sub {
		 $class->$methodname (@_)
	     })
	} keys %exportdecl};
	my $exports=
	  ((@_==1 and $_[0] eq ":all") ?
	   $exportdecl
	   :
	   +{
	     map {
		 $_=>
		   $$exportdecl{$_} // die "$_ not exported by $class"
	       } @_
	    });
	for my $name (keys %$exports) {
	    no strict 'refs';
	    *{$package."::".$name}= $$exports{$name}
	}
    }
}


1
