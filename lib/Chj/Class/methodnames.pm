#
# Copyright (c) 2004-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

Chj::Class::methodnames

=head1 SYNOPSIS

 use Chj::Class::methodnames;
 print map { "$_\n"},methodnames($someobject);

=head1 DESCRIPTION

Return all names of methods, except for those in a stoplist; also
recurses into parent packages following @ISA.


=head1 FUNCTIONS

 set_stoplist(list of methodnames not to return)
   set another list than BEGIN and Dumper.
   (It sets a new hashref at $Chj::Class::methodnames::stop.)

=cut


package Chj::Class::methodnames;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(methodnames);

use strict;


our $stop={};
sub set_stoplist {
    #my $class=shift; eh we are not a class here
    my $newstop={};
    for(@_){
	$newstop->{$_}=undef
    }
    $stop=$newstop;
}

set_stoplist(qw(
		BEGIN
		Dumper
	       ));

sub methods_of_class {
    my ($class, $maybe_ignore_codes)=@_;
    if ($class eq 'Class::Array') {
	# since I have such a mess there, I exclude that one, and
	# return a list of only some of it's methods.
	return qw(clone )
    }
    no strict 'refs';
    my $class_array_namehash= do {
	if (defined *{$class."::_CLASS_ARRAY_COUNTER"}{SCALAR}) {
	    +{
	      map { $_=>1 }
	      (@ {$class."::_CLASS_ARRAY_PUBLIC_FIELDS"},
	       @ {$class."::_CLASS_ARRAY_PUBLICA_FIELDS"},
	       @ {$class."::_CLASS_ARRAY_PROTECTED_FIELDS"},
	       @ {$class."::_CLASS_ARRAY_PRIVATE_FIELDS"})
	     }
	} else {
	    undef
	}
    };
    my $ignore_codes= defined $maybe_ignore_codes ? $maybe_ignore_codes
      : +{
	  map { $_=>1 } (
			 (*Data::Dumper::Dumper{CODE}||()),
			 (*Carp::croak{CODE}||()),
			 (*Carp::carp{CODE}||()),
			 (*Carp::confess{CODE}||()),
			 (*Carp::cluck{CODE}||())
			)
	 };
    if (my $hash= *{$class."::"}{HASH}) {
	my $code;# (ugly?)
	(
	 (
	  grep {
	      (not (exists $stop->{$_})
	       and not do {
		   # constant name of class array based class.
		   # or: constant at all?. how to find out if it's a constant?
		   $class_array_namehash and exists $class_array_namehash->{$_}
	       }
	       and $code= *{$class."::".$_}{CODE}
	       and not do {
		   # exclude carp/croak, Dumper etc.
		   $ignore_codes->{ $code }
	       })
	  }
	  keys %$hash
	 ),
	 do {
	       if (my $isa= *{$class."::ISA"}{ARRAY}) {
		   map {
		       methods_of_class($_,$ignore_codes)
		   } @$isa
	       } else {
		   ()
	       }
	   }
	)
    } else {
	()  # or exception?
    }
}


sub methodnames ( $ ) {
    my ($obj_or_class)=@_;
    my $class= ref($obj_or_class) || $obj_or_class;
    methods_of_class $class;
}

*Chj::Class::methodnames= \&methodnames;

1
