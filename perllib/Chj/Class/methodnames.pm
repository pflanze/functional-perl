# Wed Dec 22 14:18:57 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

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
    my ($class,
	#optional:
	$ignore_codes
       )=@_;
    if ($class eq 'Class::Array') {
	# since I have such a mess there, I exclude that one, and return a list of only some of it's methods.
	return qw(clone )# and maybe?: qw(class_array_namehash class_array_namehash_allprotected class_array_indices )
	  #definitely a TODO item (clean up class array (put non oo stuff out))
    }
    no strict 'refs';
    my $class_array_namehash= do {
	if (defined *{$class."::_CLASS_ARRAY_COUNTER"}{SCALAR}) {
	    #$class->class_array_namehash  ist leer.
	    #*{$class."::CLASS_ARRAY_NAMEHASH"}{HASH} existiert offenbar (noch) nicht.
	    #{ anonym hash generation geht nicht wird als block interpretiert
	    my $MANN= {# damit gehts.
		map { $_=>1 } do {
		    # get ALLL fields at once. ehr no only of that particular class, that's enough/correct, but include private fields as well.
		    # frage: wenn inherit of a field, willit be stored in the subclass as well?
		    @ {$class."::_CLASS_ARRAY_PUBLIC_FIELDS"},
		      @ {$class."::_CLASS_ARRAY_PUBLICA_FIELDS"},
			@ {$class."::_CLASS_ARRAY_PROTECTED_FIELDS"},
			  @ {$class."::_CLASS_ARRAY_PRIVATE_FIELDS"}
		      }
		      };
	    #{ @vals }  fuck geht auch nicht ???
	    #{ ha=>1, bl=>2 }
	} else {
	    undef
	}
    };
    #use Data::Dumper;
    #warn "class_array_namehash=",Dumper($class_array_namehash) if $class_array_namehash;
    $ignore_codes||= do {
	my $MANN= {
		   map { $_=>1 } (
				  (*Data::Dumper::Dumper{CODE}||()),
				  (*Carp::croak{CODE}||()),
				  (*Carp::carp{CODE}||()),
				  (*Carp::confess{CODE}||()),
				  (*Carp::cluck{CODE}||())
				 )
		  };
    };
    if (my $hash= *{$class."::"}{HASH}) {
	my $code;#helper var
	(grep {
	    not (exists $stop->{$_})
	    and not do{
		# constant name of class array based class. or: constant at all?. how to find out if it's a constant?
		#((my $a=... and $a .... geht eben NICHT.))
		$class_array_namehash and exists $class_array_namehash->{$_}
	    }
	    and $code= *{$class."::".$_}{CODE}
	    and not do {
		# exclude carp/croak, Dumper and friends, haha sigh
		$ignore_codes->{ $code }
	    }
	}
	 keys %$hash),
	   do {
	       if (my $isa= *{$class."::ISA"}{ARRAY}) {
		   map {
		       methods_of_class($_,$ignore_codes)
		   } @$isa
	       } else {
		   ()
	       }
	   }
    } else {
	()  # or exception? be nice and don't for the moment being
    }
}


sub methodnames ( $ ) {
    my ($obj)=@_;#or, well, if you really want, a class name. why not after all
    my $class= ref($obj)||$obj;
    # go scanning.
    methods_of_class $class;#warum wirklich ne andere funktion?
}

*Chj::Class::methodnames= \&methodnames;

1
