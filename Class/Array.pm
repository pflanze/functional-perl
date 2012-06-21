package Class::Array;

# Copyright 2001-2008 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself (i.e. Artistic license/GPL)


$VERSION = '0.10pre1';

use strict;
use Carp;

#use constant DEBUG=>0;
BEGIN { eval 'sub DEBUG () {'.((!!$ENV{CLASS_ARRAY_DEBUG})||0).'}'; die if $@;}
$|=1 if DEBUG;

#use enum qw(PUBLIC PROTECTED PRIVATE);
sub PUBLIC () {0}; sub PROTECTED () {1}; sub PRIVATE () {2}; # enum is not in the base perl 5.005 dist
sub PUBLICA () {3}; # (new 04/10/31) public only via accessors, not via field constant export.

# lexicalized copy from Chj::load:  (most of the code here should really not be in the base class of all class array based classes sigh..)
my $load=sub {
    for $_ (@_) {
        my $name=$_;
        $name=~ s|::|/|sg;
        $name.=".pm";
        require $name;
    }
};

sub import {
    my $class=shift;
    my $calling_class;
    # sort out arguments:
    my (@normal_import, @only_fields, @newpublicfields, @newpublicafields, @newprotectedfields, @newprivatefields, @pmixin);
    my $publicity= PROTECTED; # default behaviour!
    my $namehash;
    my ($flag_fields, $flag_extend, $flag_onlyfields, $flag_base, $flag_nowarn, $flag_namehash,
        $flag_caller, $flag_pmixin);#hmm it really starts to cry for a $i or shift approach.
    for (@_) {
        if ($flag_base) {
            $flag_base=0;
            $class= $_;
        } elsif ($flag_namehash) {
            $flag_namehash=0;
            $namehash= $_;
	} elsif ($flag_pmixin) {
	    $flag_pmixin=0;
	    push @pmixin, $_;
	    ##(or should we actually accept as many arguments as there are non-dashed ones?)
        } elsif ($flag_caller) {
            $flag_caller=0;
            $calling_class= $_;
        } elsif ($_ eq '-caller') {
            croak "Multiple occurrence of -caller argument" if defined $calling_class;
            $flag_caller=1;
        } elsif ($_ eq '-nowarn') {
            $flag_nowarn=1;
        } elsif ($_ eq '-fields' or $_ eq '-members') {
            $flag_fields=1;
        } elsif ($_ eq '-extend') {
            $flag_extend=1;
        } elsif ($_ eq '-public') {
            if ($flag_extend || $flag_fields) {
                $publicity=PUBLIC;
            } else {
                croak __PACKAGE__.": missing -extend or -fields option before -public";
            }
        } elsif ($_ eq '-publica' or $_ eq '-pub') {
            if ($flag_extend || $flag_fields) {
                $publicity=PUBLICA;
            } else {
                croak __PACKAGE__.": missing -extend or -fields option before -publica";
            }
        } elsif ($_ eq '-shared'|| $_ eq '-protected') {
            if ($flag_extend || $flag_fields) {
                $publicity=PROTECTED;
            } else {
                croak __PACKAGE__.": missing -extend or -fields option before -protected";
            }
        } elsif ($_ eq '-private') {
            if ($flag_extend || $flag_fields) {
                $publicity=PRIVATE;
            } else {
                croak __PACKAGE__.": missing -extend or -fields option before -private";
            }
        } elsif ($_ eq '-onlyfields' or $_ eq '-onlymembers') {
            if ($flag_extend || $flag_fields) {
                croak __PACKAGE__.": -onlyfields option not allowed after -extend or -fields";
            } else {
                $flag_onlyfields=1;
            }
        } elsif ($_ eq '-class') {
            if (defined $flag_base) {
                croak __PACKAGE__.": only one -class option possible";
            } else {
                $flag_base=1;
            }
            $flag_base=1;
        } elsif ($_ eq '-namehash') {
            $flag_namehash=1; ## wieso dieser hack?, warum nicht nächstes argument clobbern? Hmm.
        } elsif ($_ eq '-pmixin') {
            $flag_pmixin=1; #dito
        } elsif (/^-/) {
            croak __PACKAGE__.": don't understand option `$_'";
        } else {
            if ($flag_fields || $flag_extend) {
                if ($publicity == PUBLIC) {
                    push @newpublicfields,$class->class_array_conformize($_);
		} elsif ($publicity == PUBLICA) {
                    push @newpublicafields,$class->class_array_conformize($_);
                } elsif ($publicity == PROTECTED) {
                    push @newprotectedfields,$class->class_array_conformize($_);
                } else {
                    push @newprivatefields,$class->class_array_conformize($_);
                }
            } elsif ($flag_onlyfields) {
                push @only_fields, $_;
            } else {
                push @normal_import, $_;
            }
        }
    }

    croak "Missing argument to '-caller'" if $flag_caller;
    unless (defined $calling_class) {
        $calling_class= caller;
        croak "Won't import class '$class' into itself (use the -caller option to specify the export target)"
	  if $class eq $calling_class;
    }
    warn "importing '$class' to '$calling_class'" if DEBUG;

    #if ($flag_namehash && ! $namehash) {
    #   croak __PACKAGE__.": missing argument to -namehash option";
    #} els
    # nein, es soll undef erlaubt sein für den Fall von fields/inherit, dann einfach kein alias kreieren?
    # çç
    if ($flag_fields && defined $flag_base) {
        croak __PACKAGE__.": you can't give both -fields and -class options";
    } elsif ($flag_fields && $flag_extend) {
        croak __PACKAGE__.": you can't give both -fields and -extend options";
    } elsif ($flag_fields and $flag_onlyfields) {
        croak __PACKAGE__.": you can't give both -fields and -onlyfields options";
    } elsif ($flag_fields) {  # set up $calling_class as base class
        my $counter=0; ##PS. könnte bei 1 anfangen und ins arrayelement 0 was anderes stopfen...
        create_fields_and_bless_class ($calling_class,
				       $counter,
				       \@newpublicfields,
				       \@newpublicafields,
				       \@newprotectedfields,
				       \@newprivatefields,
				       $class);
        if ($namehash) {
            $calling_class->class_array_namehash($namehash,1,$calling_class,1);
        }

    } elsif ($flag_extend) {  # Inherit a class
        no strict 'refs';
        my $counter= $ {"${class}::_CLASS_ARRAY_COUNTER"};
        unless (defined $counter) {
            if ($class eq __PACKAGE__) {
                croak __PACKAGE__.": please use the '-fields' argument instead of '-extend' for deriving from the Class::Array base class";
                # (Hmm, does it really make sense?, should we just drop the '-fields' arg in favour of -extend in all cases?)
            } else {
                croak __PACKAGE__.": class $class doesn't seem to be a Class::Array type class";
            }
        }
        warn "    going to call create_fields_and_bless_class for extension, calling_class=$calling_class, counter=$counter, class=$class" if DEBUG;
	create_fields_and_bless_class ($calling_class,
				       $counter,
				       \@newpublicfields,
				       \@newpublicafields,
				       \@newprotectedfields,
				       \@newprivatefields,
				       $class);
        if (#  $class ne __PACKAGE__) {
	    defined $ {"${class}::_CLASS_ARRAY_SUPERCLASS"}) {
	    alias_fields ($class,
			  $calling_class,
			  $flag_onlyfields ? { map { $_=> 1 } @only_fields } : undef,
			  $flag_nowarn,
			  !$flag_fields,
			  {map { $_=>1 } @newpublicfields,@newpublicafields,@newprivatefields },
			 );
        }
        if ($namehash) {
            $calling_class->class_array_namehash($namehash,1,$calling_class,1);
        }

    } else {  # 'normal' use of a class without inheriting it.
        croak "$class is of no use without defining fields on top of it"
	  unless do {
	      no strict 'refs';
	      defined ${"${class}::_CLASS_ARRAY_SUPERCLASS"};
	  };
	# don't simply test '$class eq __PACKAGE__' since this would
	# stop one to extent Class::Array itself.
        alias_fields ($class, $calling_class, $flag_onlyfields ? { map { $_=> 1 } @only_fields } : undef, 
            $flag_nowarn, 0);
        if ($namehash) { # create (if needed) and import name lookup hash (and cache it)
            $class->class_array_namehash($namehash,0,$calling_class,1);
        }
    }

    if (@pmixin) {
	$load->(@pmixin);
	no strict 'refs';
	push @{$calling_class."::ISA"}, @pmixin;
    }

    # 'normal' export mechanism
    for (@normal_import) {
        transport ([$_],$class,$calling_class, $flag_nowarn);
    }
}


sub alias_fields {
    my ($class,
	$calling_class,
	$only_fields,
	$flag_nowarn,
	$flag_inherit,
	$ignore_fields, # optional; the opposite of only_fields, 'usually' contains those fields that have been newly created  or already aliased.
       ) =@_;
    $ignore_fields||={};
    no strict 'refs';
    if (defined *{"${class}::_CLASS_ARRAY_PUBLIC_FIELDS"}{ARRAY}) {
        for (@{"${class}::_CLASS_ARRAY_PUBLIC_FIELDS"},
	     ($flag_inherit ?
	      (@{"${class}::_CLASS_ARRAY_PROTECTED_FIELDS"},@{"${class}::_CLASS_ARRAY_PUBLICA_FIELDS"})
	      : ())
	    ) {
            if (!$only_fields or $only_fields->{$_}) {
		if ($ignore_fields->{$_}) {
		    warn "alias_fields: ignoring field '$_' in class '$class'" if DEBUG;
		} else {
		    if (defined *{"${calling_class}::$_"}{CODE}) {
			if (*{"${calling_class}::$_"}{CODE} == *{"${class}::$_"}{CODE}) {
			    warn "${calling_class}::$_ exists already but is the same as ${class}::$_" if DEBUG;
			    $ignore_fields->{$_}=1;
			} else {
			    carp __PACKAGE__.": conflicting name `$_': ignoring and also removing existing entry (all of \*$_ !)" unless $flag_nowarn;
			    #delete *{"${calling_class}::$_"}{CODE}; ## geht nicht, muss undef?:
			    #undef *{"${calling_class}::$_"}{CODE}; ## geht auch nicht, Can't modify glob elem in undef operator
			    #*{"${calling_class}::$_"}= undef; ## ist doch wüst weil es auch alle andern löscht.
			    #*{"${calling_class}::$_"}= *Class::Array::nonexistant{CODE}; ist genaudasselbe.
			    #*{"${calling_class}::$_"}= sub { print "SCheisse\n" };  #"
			    delete $ {"${calling_class}::"}{$_}; #"  OK! Works, but deletes all glob fields, not only CODE. Does anybody know how to do this correctly? In Perl?, in a C extension?
			}
		    } else {
			*{"${calling_class}::$_"}= *{"${class}::$_"}{CODE};
			$ignore_fields->{$_}=1;
		    }
		}
            }
        }
	my $superclass= $ {"${class}::_CLASS_ARRAY_SUPERCLASS"};
	warn  "! ${class}::_CLASS_ARRAY_SUPERCLASS =$superclass\n" if DEBUG;
	
        unless ( $superclass ) {
	    my $isaref= *{"${class}::ISA"}{ARRAY};
	    #print STDERR "! ${class}::ISA = ".(join ",",@$isaref )."\n";
	    if ($isaref and @$isaref >= 1) {
		$superclass =  $ {$isaref}[0];
	    }
	}
        $superclass or do { 
	    warn __PACKAGE__.": Error: class $class is set up as Class::Array type class except that _CLASS_ARRAY_SUPERCLASS is not defined" unless $class eq 'Class::Array';     ### don't warn when class = Class::Array, happens often
	    return;
	};

        alias_fields ( $superclass, $calling_class, $only_fields, $flag_nowarn, $flag_inherit, $ignore_fields);
    } # else something is strange, isn't it? ##
}

#use Carp 'cluck';

# von theaterblut:
sub class_array_namehash_allprotected { # get all protected field definitions in the given package/package of given object, regardless of caller
    my $proto=shift;
    my $class= ref($proto)||$proto; #minimal gefahrlich 
    #warn "class_array_namehash_allprotected: class=$class";
    my $hashref;
    no strict 'refs';
    if ($hashref= *{"${class}::_CLASS_ARRAY_NAMEHASHALLPROTECTED"}{HASH}) {
	#warn "reuse cached hash";
    } else {
	$hashref={}; # könnte es ja sein dass gar nirgends protected fields sind!
	my $workclass=$class;
	do {
	    #warn "class_array_namehash_allprotected: werde über \@${workclass}::_CLASS_ARRAY_PROTECTED_FIELDS loopen..";
	    for (@{"${workclass}::_CLASS_ARRAY_PROTECTED_FIELDS"}) {
		$hashref->{$_}= eval "${workclass}::$_";
		#warn "class_array_namehash_allprotected: did set name '$_' to $hashref->{$_}";
	    }
	} while ($workclass= ${"${workclass}::_CLASS_ARRAY_SUPERCLASS"});
	*{"${class}::_CLASS_ARRAY_NAMEHASHALLPROTECTED"}= $hashref;
    }
    return $hashref
}

sub class_array_namehash { #(cj 05/10/05: offensichtlich keine publica felder bekommbar so, egal was für flags.??)
    my $class=shift;
    my ($hashname, $flag_inherit, $calling_class, $flag_cachehash, $incomplete_hashref) =@_;
    $calling_class= caller unless defined $calling_class;
    $flag_inherit= ( $calling_class->isa($class) || $class->isa($calling_class) )
      unless defined $flag_inherit;
    no strict 'refs';
    my $hashref;
    if ($hashref=
	$flag_inherit ?
	*{"${calling_class}::CLASS_ARRAY_NAMEHASH"}{HASH}
        :
	*{"${class}::_CLASS_ARRAY_NAMEHASHFOREXTERNALUSE"}{HASH}
       ) {
        warn "using cached namehash for '$class'" if DEBUG;
    } else {
	warn "need to create it" if DEBUG;
	$hashref= $incomplete_hashref ? $incomplete_hashref : {};
	my $superclass= $ {"${class}::_CLASS_ARRAY_SUPERCLASS"};
	if ($superclass) {
	    warn "DEBUG: going to call $superclass->class_array_namehash(undef, $flag_inherit, $calling_class, 0, \$hashref) where hash has ".(keys %$hashref)." keys" if DEBUG;
	    $superclass->class_array_namehash(undef, $flag_inherit, $calling_class, 0, $hashref); ## eigentlich würd ein flag anstelle calling_class ja reichen.
	    warn "DEBUG: now hash has ".(keys %$hashref)." keys" if DEBUG;
	}
#	use Data::Dumper;
#	warn "Public: ",Dumper(\@{"${class}::_CLASS_ARRAY_PUBLIC_FIELDS"});
#	warn "Publica: ",Dumper(\@{"${class}::_CLASS_ARRAY_PUBLICA_FIELDS"});
        for (@{"${class}::_CLASS_ARRAY_PUBLIC_FIELDS"},
	     @{"${class}::_CLASS_ARRAY_PUBLICA_FIELDS"},
	     ($flag_inherit ? @{"${class}::_CLASS_ARRAY_PROTECTED_FIELDS"}: ()),
	     (($flag_inherit and $calling_class eq $class) ? @{"${class}::_CLASS_ARRAY_PRIVATE_FIELDS"}: ())
	    ) {
            #if (exists $hashref->{$_}) {
            #    warn "DUPLIKAT KEY für '$_' in '$class'";##
            #} nope just overwrite it. since we first gathered the superclass'es values first, we have to.
            $hashref->{$_}= eval "${class}::$_";
        }
        # save it?
	if ($hashname or $flag_cachehash) {
            if ($flag_inherit) {
                *{"${calling_class}::CLASS_ARRAY_NAMEHASH"}= $hashref;
		warn "DEBUG: saved namehash as ${calling_class}::CLASS_ARRAY_NAMEHASH" if DEBUG;
            } else {
                *{"${class}::_CLASS_ARRAY_NAMEHASHFOREXTERNALUSE"}= $hashref;
		warn "DEBUG: saved namehash as ${class}::_CLASS_ARRAY_NAMEHASHFOREXTERNALUSE" if DEBUG;
            }
        }
    }
    # create alias for it?
    if ($hashname and $hashname ne '1' and (!$flag_inherit or $hashname ne 'CLASS_ARRAY_NAMEHASH')) {
        *{"${calling_class}::$hashname"}= $hashref;
    }

    $hashref
}

sub class_array_indices {
    my $class=shift;
    my $hash= $class->class_array_namehash(undef,undef,caller); # is is required to get caller already here!, it would be Class::Array otherwise
#use Data::Dumper;
#warn "class_array_indices bekam ".Dumper($hash);
    map { exists $hash->{$_} ? $hash->{$_} : confess "class_array_indices: '$_': no such field (known in your namespace)" } @_;
}

sub transport {
    my ($items, $class, $calling_class, $flag_nowarn)=@_;
    no strict 'refs';
    for (@$items) {
        if (/^\$(.*)/) { # scalar
            if (defined *{"${class}::$1"}{SCALAR}) { ## DOES IN FACT ALWAYS RETURN TRUE!
                if (defined *{"${calling_class}::$1"}{SCALAR}) { ## DOES IN FACT ALWAYS RETURN TRUE!
                    if (*{"${calling_class}::$1"}{SCALAR} == *{"${class}::$1"}{SCALAR}) {
                        carp __PACKAGE__.": symbol `$_' already imported" if DEBUG;
                    } else {
                        carp __PACKAGE__.": conflicting name `$_' - ignoring" unless $flag_nowarn;
                    }
                } else {
                    *{"${calling_class}::$1"}= *{"${class}::$1"}{SCALAR};
                }
            } else {
                croak __PACKAGE__.": can't export \$${class}::$1 since it doesn't exist";
            }
        } elsif (/^\@(.*)/) { # array
            if (defined *{"${class}::$1"}{ARRAY}) {
                if (defined *{"${calling_class}::$1"}{ARRAY}) { 
                    if (*{"${calling_class}::$1"}{ARRAY} == *{"${class}::$1"}{ARRAY}) {
                        carp __PACKAGE__.": symbol `$_' already imported" if DEBUG;
                    } else {
                        carp __PACKAGE__.": conflicting name `$_' - ignoring" unless $flag_nowarn;
                    }
                } else {
                    *{"${calling_class}::$1"}= *{"${class}::$1"}{ARRAY};
                }
            } else {
                croak __PACKAGE__.": can't export \@${class}::$1 since it doesn't exist";
            }
        } elsif (/^\%(.*)/) { # hash
            if (defined *{"${class}::$1"}{HASH}) {
                if (defined *{"${calling_class}::$1"}{HASH}) {
                    if (*{"${calling_class}::$1"}{HASH} == *{"${class}::$1"}{HASH}) {
                        carp __PACKAGE__.": symbol `$_' already imported" if DEBUG;
                    } else {
                        carp __PACKAGE__.": conflicting name `$_' - ignoring" unless $flag_nowarn;
                    }
                } else {
                    *{"${calling_class}::$1"}= *{"${class}::$1"}{HASH};
                }
            } else {
                croak __PACKAGE__.": can't export \%${class}::$1 since it doesn't exist";
            }
        } else { # subroutine/constant
            if (defined *{"${class}::$_"}{CODE}) {
                if (defined *{"${calling_class}::$_"}{CODE}) {
                    if (*{"${calling_class}::$_"}{CODE} == *{"${class}::$_"}{CODE}) {
                        carp __PACKAGE__.": symbol `$_' already imported" if DEBUG;
                    } else {
                        carp __PACKAGE__.": conflicting name `$_' - ignoring" unless $flag_nowarn;
                    }
                } else {
                    *{"${calling_class}::$_"}= *{"${class}::$_"}{CODE};    #"
                }
            } else {
                croak __PACKAGE__.": can't export ${class}::$_ since it doesn't exist";
            }
        }
    }
}
#use Carp 'cluck';
# sub create_name_lookup_hash { # only call this if needed since it's slow; only call if sure that the given class is Class::Array based.
#   my $class=shift;
# #cluck "DEBUG: create_name_lookup_hash for class '$class'";
#   my $superclass;
#   no strict 'refs';
#   for (@{"${class}::ISA"}) {
#       if (defined ${"${_}::_CLASS_ARRAY_COUNTER"}) { # ok it's the class::array based class
#           $superclass=$_;
# 
#           # copy lookup hash from super class
#           unless (*{"${superclass}::CLASS_ARRAY_NAMEHASH"}{HASH}) {
#               $superclass->create_name_lookup_hash;
#           }
#           %{"${class}::CLASS_ARRAY_NAMEHASH"}= %{"${superclass}::CLASS_ARRAY_NAMEHASH"};
# 
#           last;# for
#       }
#   } # else there is no superclass. (Except ("hopefully") Class::Array itself)
#   
#   # Put members from this class into the hash
#   for (@{"${class}::_CLASS_ARRAY_PUBLIC_FIELDS"}, @{"${class}::_CLASS_ARRAY_PROTECTED_FIELDS"}, @{"${class}::_CLASS_ARRAY_PRIVATE_FIELDS"}) {
#       ${"${class}::CLASS_ARRAY_NAMEHASH"}{$_}= eval "${class}::$_";
#   }
# }

sub create_fields_and_bless_class {
    my ($calling_class,
	$counter,
	$newpublicfields,
	$newpublicafields,
	$newprotectedfields,
	$newprivatefields,
	$class)=@_;
    no strict 'refs';
#   if ($namehash and $class ne __PACKAGE__) { # last compare is needed (for -fields creation step) to stop from creating stuff in Class::Array itself
# ##ç               defined ${"${class}::_CLASS_ARRAY_COUNTER"}) {
# ##der scheiss ist   aber eigtl sollt ichs doch von oben von params her kriegen?
#       # copy nameindex from inherited class.
#       unless (*{"${class}::CLASS_ARRAY_NAMEHASH"}{HASH}) {
#           $class->create_name_lookup_hash;
#       }
#       %{"${calling_class}::CLASS_ARRAY_NAMEHASH"}= %{"${class}::CLASS_ARRAY_NAMEHASH"};
#   }
    for (@$newpublicfields, @$newpublicafields, @$newprotectedfields, @$newprivatefields) {
        if (defined *{"${calling_class}::$_"}{CODE}) { # coderef exists
            croak __PACKAGE__.": conflicting name `$_': can't create initial member constant";
        } else {
            my $scalar= $counter++;
            *{"${calling_class}::$_"}= sub () { $scalar };
            # The following isn't any better. It's accelerated in both cases (perl5.00503). In both cases the constants are valid during global destruction. The following doesn't work if $_ eq 'ç' or some such.
            #eval "sub ${calling_class}::$_ () { $scalar }"; ## somewhat dangerous, maybe we should check vars
            #warn "Class::Array: $@ (`$_')" if $@;
#           if ($namehash) {
#               ${"${calling_class}::CLASS_ARRAY_NAMEHASH"}{$_}=$scalar;
#           }
        }
        }
#    warn "    create_fields_and_bless_class: calling_class=$calling_class, newpublicfields=".Data::Dumper::Dumper($newpublicfields).", newprotectedfields=".Dumper($newprotectedfields).", newprivatefields=".Dumper($newprivatefields) if DEBUG;
    *{"${calling_class}::_CLASS_ARRAY_PUBLIC_FIELDS"}= $newpublicfields;
    *{"${calling_class}::_CLASS_ARRAY_PUBLICA_FIELDS"}= $newpublicafields;
    *{"${calling_class}::_CLASS_ARRAY_PROTECTED_FIELDS"}= $newprotectedfields;
    *{"${calling_class}::_CLASS_ARRAY_PRIVATE_FIELDS"}= $newprivatefields; # required for creating name lookup hashes and the like.
    *{"${calling_class}::_CLASS_ARRAY_COUNTER"}= \$counter;
    *{"${calling_class}::ISA"}= [$class];
    *{"${calling_class}::_CLASS_ARRAY_SUPERCLASS"}= \$class;
}


sub createaccessors {
    my ($calling_class)=@_;
    no strict 'refs';
    my $public = *{"${calling_class}::_CLASS_ARRAY_PUBLIC_FIELDS"}{ARRAY};
    my $publica = *{"${calling_class}::_CLASS_ARRAY_PUBLICA_FIELDS"}{ARRAY};
    if (!$publica) {
	croak __PACKAGE__."::createaccessors: class '$calling_class' does not seem to be a Class::Array based class";
    }
    my $namehash= $calling_class->class_array_namehash;
#    use Data::Dumper;
#    warn "createaccessors: for '$calling_class', namehash=",Dumper($namehash),", public= ",Dumper($public),", publica=",Dumper($publica);
    for (@$public, @$publica) {
#	warn "loop: $_";
	my $methodbasename= lcfirstletter($_);
	if (not defined *{"${calling_class}::$methodbasename"}{CODE}) {
	    *{"${calling_class}::$methodbasename"} = eval 'sub { shift->['.$namehash->{$_}.'] }';
	    die if $@;
	    #warn "did create '${calling_class}::$methodbasename'";
	}
	if (not defined *{"${calling_class}::set_$methodbasename"}{CODE}) {
	    *{"${calling_class}::set_$methodbasename"} = eval 'sub {my $s=shift; ($$s['.$namehash->{$_}.'])=@_ }';
	    die if $@;
	    #warn "did create '${calling_class}::set_$methodbasename'";
	}
    }
}

sub end {# or finalize or so.
    my $calling_class=caller;
    createaccessors($calling_class);
    1; # so that the end call can be the last statement in a module.
}

# "callback" on reading the class.  ps. this should not be done by a method here, but in a different axe (would that be mop like?)
sub class_array_conformize {
    shift;
    # if a all-lowercase fieldname is given, upcase the first letter
    my ($name)=@_;
    if (lc($name) eq ($name)) {
	ucfirstletter($name)
    } else {
	$name
    }
}

# those are functions and should be in their own namespace
sub ucfirstletter {
    my ($str)=@_;
    $str=~ s/([a-zA-Z])/uc($1)/se; # or warn ... but we don't care here.
#    warn "ucfirstletter: @_ -> $str";
    $str;
}
sub lcfirstletter {
    my ($str)=@_;
    $str=~ s/([a-zA-Z])/lc($1)/se; # or warn ... but we don't care here.
#    warn "lcfirstletter: @_ -> $str";
    $str;
}


# default constructor:
sub new {
    my $class=shift;
    bless [], $class;
}
# default cloner:
sub clone {
    my $self=shift;
    my @new=@$self;
    bless \@new,ref($self)
}
# default destructor: (this is needed so subclasses can call ->SUPER::DESTROY regardless whether there is one or not)
sub DESTROY {
}


# sub dump {
#     my $s=shift;
#     # eruiere visible fields
#     my $caller=caller;
#     #my $namehash= $s->class_array_namehash(undef,undef,$caller);
#     # nope. mannn muss doch schon was geben?
#     # all publicly available fields only?
#     # oder soll ich echt einfach durch alle Felder gehen, sie dann nach priv/prot/publ zusammenfassen öh  unddann ausgeben regardless of feldname? fully qualified feldname geben?
#     # eigentlich will ich ne darstellung  mit feld konstanten? non fully qual optional
#     die "unfinishedç"
# #    use Data::Dumper;
# #    Dumper $namehash
# }


sub class_array_publica_fields {
    my ($class,$result)=@_;
    if(ref$class) {$class= ref $class} # so that it can be used as object method,too.
    $result||=[];
    no strict 'refs';
    my $publica= *{"${class}::_CLASS_ARRAY_PUBLICA_FIELDS"}{ARRAY};
    if (!$publica) {
	croak __PACKAGE__."::class_array_publica_fields: class '$class' does not seem to be a Class::Array based class";
    }
    unshift @$result,@$publica;
    # und MUSS ich noch hoch iterieren oder nicht? DOCH man muss.
    my $superclass= *{"${class}::_CLASS_ARRAY_SUPERCLASS"}{SCALAR};
    if ($$superclass) {# auf $superclass prüfen geht eben nicht, das ist immer ein true ref. MANN. todo oben ist das wohl überall buggy.
	#warn "superclass '$$superclass'\n";
	class_array_publica_fields($$superclass,$result)
    } else {
	@$result
    }
}

sub dump_publica {
    my $s=shift;
    require Chj::singlequote;
    "$s:\n".join("",map{
	my $field=$_;
	my $method=lcfirstletter $field;
	"  $method: ".Chj::singlequote($s->$method)."\n"
    } $s->class_array_publica_fields)
}

*dump= *dump_publica; # as long as we don't have a better dump method; note that I'm almost always using publica fields now, so that's just fine for me most of the time..

1;
__END__

=head1 NAME

Class::Array - array based perl objects

=head1 SYNOPSIS

 package My::BaseClass;
 use strict;
 use Class::Array -fields=> -public=> qw(Name Firstname),
                            -protected=> qw(Age),
                            -private=> qw(Secret);

 # Method example
 sub age {
     my $self=shift;
     if (@_) {
         my $val=shift;
         if ($val>=18) {
             $self->[Age]=$val;
         } else {
             carp "not old enough";
             $self->[Secret]=$val;
         }
     } else {
         $self->[Age]
     }
 }
 ----
 package My::DerivedClass;
 use strict;
 use My::BaseClass -extend=> -public=> qw(Nickname),
                             -private=> qw(Fiancee);

 # The best way to generate an object, if you want to 
 # initialize your objects but let parent classes 
 # initialize them too:
 sub new {
     my $class=shift;
     my $self= $class->SUPER::new;
        # Class::Array::new will catch the above if 
        # no one else does
     # do initialization stuff of your own here
     $self
 }

 sub DESTROY {
     my $self=shift;
     # do some cleanup here
     $self->SUPER::DESTROY; 
        # can be called without worries, 
        # Class::Array provides an empty default DESTROY method.
 }
 
 ----
 # package main:
 use strict;
 use My::DerivedClass;
 my $v= new My::DerivedClass;
 $v->[Name]= "Bla";
 $v->age(19);
 $v->[Age]=20; # gives a compile time error since `Age' 
               # does not exist here


=head1 DESCRIPTION

So you don't like objects based on hashes, since all you can do to  prevent
mistakes while accessing object data is to create accessor methods which are
slow and inconvenient (and you don't want to use depreciated  pseudohashes
either) - what's left? Some say, use constants and  array based objects. Of
course it's a mess since the constants and the objects aren't coupled, and
what about inheritance? Class::Array tries to help you with that.

Array based classes give the possibility to access data fields of your
objects directly without the need of slow (and inconvenient) wrapper methods
but still with some protection against typos and overstepping borders of
privacy.

=head1 USAGE

Usage is somewhat similar to importing from non-object oriented modules. `use
Class::Array', as well as `use ' of any Class::Array derived class,  takes a
number of arguments. These declare which parent class you intend to use, and
which object fields you want to create. See below for an explanation of all
options. Option arguments begin with a minus `-'

Arguments listed I<before the first option> are interpreted as symbol names
to be imported into your namespace directly (apart from the field names).
This is handy to import constants and `L<enum|enum>'s. (Note that unlike the
usual L<Exporter|Exporter>, the one from Class::Array doesn't look at the
@EXPORT* variables yet. Drop me a note if you would like to have that.)

=over 4

=item -fields => I<list>

This option is needed to set up an initial Class::Array based class (i.e. not
extend an existing class). The following arguments are the names of the object
fields in this class. (For compatibility reasons with older versions of this
module, `-members' is an alias for -fields.)

=item -extend => I<list>

This is used to inherit from an existing class. The following names are
created in addition to the member names inherited from the parent class.

=item -public | -protected | -private => I<list>

These options may be used anywhere after the -fields and -extend options to
define the scope of the subsequent names. They can be used multiple times.
Public means, the member will be accessible from anywhere your class is
`use'd.
Protected means, the member will only be accessible from the class itself as
well as from derived classes (but not from other places your class is used). 
Private means, the member will only be accessible inside the class which has
defined it. (For compatibility reasons with older versions there is also a
`-shared' option which is the same as protected.)

Note that you could always access all array elements
by numeric index, and you could also fully qualify the member name
constant in question. The member name is merely not put `before your nose'.

The default is protected.

=item -onlyfields I<list>

Optional. List the fields you want to use after this option. If not given,
all (public) member names are imported. Use this if you have name conflicts
(see also the IMPORTANT section). (`-onlymembers' is an alias for -onlyfields.)

=item -nowarn

If you have a name conflict, and you don't like being warned all the time,
you can use this option (instead of explicitely listing all non-conflicting
names with -onlyfields).

=item -class => 'Some::Baseclass'

In order to make it possible to define classes independant from module files
(i.e. package Some::Baseclass is not located in a file .../Some/Baseclass.pm)
you can inherit from such classes by using the -class option. Instead of `use
Some::Baseclass ...'  you would type `use Class::Array
-class=>"Some::Baseclass", ...'.

=item -namehash => 'hashname'

By default, there is no way to convert field name strings into the 
correspondent array index except to use eval ".." to interpret the string 
as a constant. If you need fast string-to-index lookups, use this option
to get a hash with the given name into your namespace that has the field
name strings as keys and the array index as value.

Use this only if needed since it takes some time to create the hash.

Note that the hash only has the fields that are accessible to you.

You could use the reverse of the hash to get the field names for an index,
i.e. for debugging.

There's also a C<class_array_namehash> class method with which you can create the hash 
(or get the cached copy of it) at a later time:

 class->class_array_namehash( [ aliasname [, some more args ]] )

This returns a reference to the hash. Depending on whether you are in a
class inheriting from 'class' or not, or whether you *are* the 'class' or not,
you will get a hash containing protected (and your private) fields or not.
If 'aliasname' is given, the hash is imported into your namespace with that name.

To get a list of indices for a list of field names, there is also a method:

 class->class_array_indices( list of fieldnames )

This will croak if a field doesn't exist or is not visible to you.

=back


=head1 IMPORTANT

1.) Be aware that object member names are defined as constants (like in the
`L<constant|constant>' module/pragma) that are independant from the actual
object. So there are two sources of mistakes: 

=over 4

=item * Use of member names that are also used as subroutine names, perl
builtins, or as member names of another array based class you use in the same
package (namespace). When a particular name is already used in your namespace
and you call `use' on a Class::Array  based class, Class::Array will detect
this, warn you and either die (if it's about a member name you're about to
newly create), or both not import the member name into your namespace and
also *remove* the existant entry, so you can't accidentally use the wrong
one. You can still access the field by fully qualifying it's constant name,
i.e. $v->[My::SomeClass::Name] (note that this way you could also access
private fields). Use the -onlyfields or -nowarn options if you don't like the
warning messages.

=item * Using the member constants from another class than the one the object
belongs to. I.e. if you have two classes, `My::House' and `My::Person', perl
and Class::Array won't warn you if you accidentally type $me->[Pissoire]
instead of $me->[Memoire]. 

=back


2.) The `use Class::Array' or `use My::ArraybasedClass' lines should always
be the *LAST*  ones importing something from another module. Only this way
name conflicts can be detected by Class::Array. But there is one important
exception to this rule: use of other Class::Array based modules should be
even *later*. This is to resolve circularities: if there are two array
bases modules named A and B, and both use each other, they will have to
create their field names before they can be imported by the other one.
To rephrase: always put your "use" lines in this order: 1. other, not
Class::Array based modules, 2. our own definition, 3. other Class::Array
based modules.

3.) Remember that Class::Array relies on the module import mechanism and
thus on it's `import' method. So either don't define subroutines called
`import' in your modules, or call SUPER::import from there after having
stripped the arguments meant for your own import functionality, and 
specify -caller=> scalar caller() as additional arguments.

4.) (Of course) remember to never `use enum' or `use constant' to define your
field names. (`use enum' is fine however for creating *values* you
store in your object's fields.)

5.) Don't forget to `use strict' or perl won't check your field names!

=head1 TIPS

=over 4

=item * To avoid name conflicts, always use member names starting with an
uppercase letter (and the remaining part in mixed case, so to distinguish
from other constants), and use lowercase names for your methods / subs.
Define fields private, if you don't need them to be accessible outside 
your class.

=back

=head1 BUGS

Scalars can't be checked for conflicts/existence. This is due to a strange
inconsistency in perl (5.00503 as well as 5.6.1). This will probably
not have much impact. (Note that constants are not SCALARs but CODE
entries in the symbol table.)

=head1 CAVEATS

Class::Array only supports single inheritance. I think there's no way to
implement multiple inheritance with arrays / member name constants. Another
reason not to use multiple inheritance with arrays is that  users can't both
inherit from hash and array based classes, so any class aiming to be
compatible to other classes to allow multiple inheritance  should use the
standard hash based approach.

There is now a -pmixin => class 
Note that you can still force multiple inheritance by loading further
subclasses yourself ('use Classname ()' or 'require Classname') and
push()ing the additional classnames onto @ISA.
(But for Class::Array, subclasses of such a class will look as they
would only inherit from the one class that Class::Array has been told of.)

=head1 NOTE

There is also another helper module for array classes (on CPAN),
L<Class::ArrayObjects|Class::ArrayObjects> by Robin Berjon. I didn't know
about his module at the time I wrote Class::Array. You may want to have a
look at it, too.

=head1 FAQ

(Well it's not yet one but I put this in here before it becomes one:)

=over 4

=item Q: Why does perl complain with 'Bareword "Foo" not allowed' when I have defined Foo as -public in class X and I have a 'use X;' in my class Y?

A: Could it be there is a line 'use Y;' in your X module and you have placed it before defining X's fields?
(See also "IMPORTANT" section.)

=back

=head1 AUTHOR

Christian Jaeger <christian at jaeger mine nu>. Published under the
same terms as perl itself.

=head1 SEE ALSO

L<constant>, L<enum>, L<Class::Class>, L<Class::ArrayObjects>

=cut

