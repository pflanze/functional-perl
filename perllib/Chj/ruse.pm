# Sun Oct  9 04:44:07 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::ruse - reload modules

=head1 SYNOPSIS

 use Chj::repl;
 use Foo;
 use Chj::ruse;
 use Bar qw(biz bim);
 repl;
 # edit the Foo.pm or Bar.pm files, then (possibly from the repl):
 > ruse; # reloads all changed modules, and re-does all imports
         # which have happened for those modules since Chj::ruse has
         # been loaded.

=head1 DESCRIPTION

Extended copy of Module::Reload which modifies Exporter.pm so
that exports are tracked, so that these are redone as well.

One function is exported: ruse. It does the equivalent
of Module::Reload->check, and re-exports stuff as far as possible.

The function takes an optional argument: a temporary new debug level,
which shadows the default one stored in $Chj::ruse::DEBUG.
0 means no debugging info. -1 means be very silent (set $^W to false,
to prevent redefinitions of subroutines *which are NOT in the namespace
being reloaded* (subroutines in the namespace being reoaded are deleted
first, so there is never given a warning in this 'normal' case)).

=head1 BUGS

Each time import is called on a particular modules ("use Foo qw(biz baz)"),
the previous import arguments from the previous call is forgotten.
Thus if a module is use'd/import'ed multiple times in a row from the
same source file, only part of the import list is remembered. Thus
not everything is re-exported by ruse.
(Can this be solved?)

Hm, if an error prevented a module from having been loaded, somehow
reload doesn't (always?) work ? why?

This module might have problems with threads - I don't know if
other threads might try to run subroutines which have been deleted before
being defined again.

=cut


# formerly: "but no: use Module::Reload and Module::Reload->check instead. Or again.pm."

#" Hm, "Class::Array: conflicting name `....': can't create initial member constant..""


package Chj::ruse;
#@ISA="Exporter";
require Exporter;
#@EXPORT_OK=qw();
use strict;
use Carp;
our $DEBUG=0; # -1 = more than normal-silent. 0 = no debugging. 1,2,3= debugging levels.

#use Module::Reload;

# make sure it is loaded, and unmodified?
#delete $INC{'Exporter.pm'};
##delete $INC{'Exporter/Heavy.pm'};
#require Exporter;
#nah forget it. we are loaded only once (normally), so them modified once only too.aswell.

#*Exporter::orig_import = \&Exporter::import;
our $orig_import= \&Exporter::import;

our %rdep; # moduleclassname => caller => [ import-arguments ]

sub new_import {
    warn "new_import called" if $DEBUG>2;
    my $caller=caller;
    #my $class=shift;
    my ($class)=@_;
    #$rdep{$class}{$caller}=[@_[1..$#_]];
    $rdep{$class}{$caller}=[@_];#warum nicht gleich alle. dann auch einfacher aufzurufen ?.
    goto $orig_import;
}

{
    local $^W= ($DEBUG>0);# ? $^W : 0; ghetnicht?!?
    *Exporter::import= \&new_import;
}

{
    package Chj::ruse::Reload;
    # modified copy from Module::Reload
    our %Stat;
    our $Debug; #*Debug= \$Chj::ruse::DEBUG;
    sub wipeout_namespace {
	my ($key)=@_;
	my $class=$key;
	$class=~ s|/|::|sg;##COPY!!below.
	$class=~ s|\.pm$||s;
	my $h= do {
	    no strict 'refs';
	    \%{"${class}::"}
	};
	for (keys %$h) {
	    unless (/[^:]::\z/) {
		delete $$h{$_};
		warn "deleted '$_'" if $Chj::ruse::DEBUG > 0;
	    }
	}
    }
    sub check {
	$Debug= $Chj::ruse::DEBUG;#nur so gehts wenn jener local macht? wahnsinn, ja.!!!!!
	my $c=0;
	my @ignores;
	push @ignores,$INC{"Module/Reload.pm"} if exists $INC{"Module/Reload.pm"};
	push @ignores,$INC{"Chj/ruse.pm"} if exists $INC{"Chj/ruse.pm"};
	#no warnings 'redefine' unless $Debug; syntax error
	local $^W= ($Debug>=0); # ? $^W : 0; gehtnich
	my $memq_ignores= sub { my ($f)=@_; for(@ignores) {return 1 if $_ eq $f} 0};
	while (my($key,$file) = each %INC) {
	    next if $memq_ignores->($file);#too confusing
	    #local $^W = 0; nope, only shut down redefinition warnings please. ç
	    my $mtime = (stat $file)[9];
	    $Stat{$file} = $^T
	      unless defined $Stat{$file};
	    warn "Module::Reload: stat '$file' got $mtime >? $Stat{$file}\n"
	      if $Debug >= 3;
	    if ($mtime > $Stat{$file}) {
		delete $INC{$key};
		wipeout_namespace($key);
		eval {
		    local $SIG{__WARN__} = \&warn;  ##cj: was macht das?
		    require $key;
		};
		if ($@) {
		    warn "Module::Reload: error during reload of '$key': $@\n"
		}
		else {
		    if ($Debug>0) {
			warn "Module::Reload: process $$ reloaded '$key'\n"
			  if $Debug == 1;
			warn("Module::Reload: process $$ reloaded '$key' (\@INC=".
			     join(', ',@INC).")\n")
			  if $Debug >= 2;
		    }
		    Chj::ruse::reimport($key);
		    #if ($Debug) ach lass das reimport machen.
		}
		++$c;
	    }
	    $Stat{$file} = $mtime; ##(cj sollte es nicht auf ewig warnen wenn es nicht reloaden konnte?)
	}
	$c;
    }
}

sub reimport {
    my ($key)=@_;
    my $class=$key;
    $class=~ s|/|::|sg;##COPY above !!
    $class=~ s|\.pm$||s;
    if (my $importer= $class->can("import")) { ##hmm. aufgepasst? falsch sogar. muss ja Exporter::import sein. aber na kann das ja noch prüfen.
#	if ($importer eq \&Exporter::import) {
	    my $imports= $rdep{$class};
	    for my $caller (keys %$imports) {
		#$importer->(@{$$imports{$caller}});
		#hmm und now how do we set up caller.
		#calc> :l caller(0)=("haha","hoho",22)
		#Can't modify caller in scalar assignment at (eval 34) line 2, at EOF
		#wenn doch perl schon alles hacking zulässt, warum nicht auch das?
		my $code= "package $caller; ".'$Chj::ruse::orig_import->(@{$$imports{$caller}})';
		eval $code;
		if (ref$@ or $@) {
		    warn "reimport WARNING: evaling '$code' gave: $@";
		}
	    }
# 	}
# 	else {
# 	    warn "reimport: $class->can('import') returned another routine than Exporter::import, so doing nothing to be careful";# sinnlos?  ich will wissen  ob der code  wieder täte.  doch hiermit finde ich das ja doch nicht raus ?.   AH ps. und namespace cleanen ist noch nicht done.  na das darf ich aber eh nicht?  aber @ISA und so  wenn das neu modul nicht mehr hat?   och   ist es SO schwer?  alles kleanen ginge ja schon  doch dann wird state info auch weg geräumt. aber ist wohl einzig saubere variante.
# 	}
    } else {
	warn "reimport WARNING: $class->can('import') didn't yield true, seems the module doesn't inherit from Exporter any more ?";
    }
}

#CHECK {#delay this until Chj::ruse.pm is finished loading so that it is in %INC itself (to avoid uninitialized warnings in check above)  but no, too late to run CHECK block. under repl.
Chj::ruse::Reload->check;
#}

sub ruse {
    @_ > 1 and croak "ruse only takes 0 or 1 arguments";
    local $DEBUG=( @_ ? $_[0] : $DEBUG);
    #local $DEBUG=1;
    #warn "DEBUG=$DEBUG";
    Chj::ruse::Reload->check;
}

sub import {
    #my $caller=shift;
    my $caller=caller;#mann ich döbel
    no strict 'refs';
    warn "Kopiere ruse funktion nach '${caller}::ruse'" if $DEBUG>1;
    *{"${caller}::ruse"}= \&ruse; #na, kein renamenichts?
}


1
