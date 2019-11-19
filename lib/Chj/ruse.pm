#
# Copyright (c) 2004-2014 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::ruse - reload modules

=head1 SYNOPSIS

 use FP::Repl;
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


package Chj::ruse;
require Exporter;
use strict; use warnings; use warnings FATAL => 'uninitialized';
use Carp;
our $DEBUG=0; # -1 = more than normal-silent. 0 = no debugging. 1,2,3= debugging levels.

our $orig_import= \&Exporter::import;

our %rdep; # moduleclassname => caller => [ import-arguments ]

sub new_import {
    warn "new_import called" if $DEBUG>2;
    my $caller=caller;
    my ($class)=@_;
    $rdep{$class}{$caller}=[@_];
    goto &$orig_import;
}

{
    no warnings "redefine";
    local $^W= ($DEBUG>0);
    *Exporter::import= \&new_import;
}

{
    package Chj::ruse::Reload;
    # modified copy from Module::Reload

    our %Stat;
    our $Debug;

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
        $Debug= $Chj::ruse::DEBUG;  # so that it works when that one's local'ized
        my $c=0;
        my @ignores;
        push @ignores,$INC{"Module/Reload.pm"}
          if exists $INC{"Module/Reload.pm"};
        push @ignores,$INC{"Chj/ruse.pm"}
          if exists $INC{"Chj/ruse.pm"};
        local $^W= ($Debug>=0);
        my $memq_ignores= sub {
            my ($f)=@_;
            for (@ignores) {
                return 1 if $_ eq $f
            }
            0
        };
        while (my ($key, $file) = each %INC) {
            my $reload= sub {
                delete $INC{$key};
                wipeout_namespace($key);
                eval {
                    local $SIG{__WARN__} = \&warn;  # (cj: what does that do?)
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
                }
                ++$c;
            };
            if (! defined $file) {
                &$reload;
                my $file2 = $INC{$key};
                my $mtime = (stat $file2)[9];
                $Stat{$file2} = $mtime;
            } else {
                next if $memq_ignores->($file); # too confusing
                #local $^W = 0; XX nope, only shut down redefinition warnings please.
                my $mtime = (stat $file)[9];
                $Stat{$file} = $^T
                  unless defined $Stat{$file};
                warn "Module::Reload: stat '$file' got $mtime >? $Stat{$file}\n"
                  if $Debug >= 3;
                &$reload if ($mtime > $Stat{$file});
                $Stat{$file} = $mtime;
                # (XX shouldn't let it warn forever if it couldn't reload?)
            }
        }
        $c;
    }
}

our $verbose= 0;

sub reimport {
    my ($key)=@_;
    my $class=$key;
    $class=~ s|/|::|sg;##COPY above !!
    $class=~ s|\.pm$||s;
    if (my $importer= $class->can("import")) {
        my $imports= $rdep{$class};
        for my $caller (keys %$imports) {
            my $code= "package $caller; "
              .'$Chj::ruse::orig_import->(@{$$imports{$caller}})';
            eval $code; # XX is this safe? (security)
            if (ref $@ or $@) {
                warn "reimport WARNING: evaling '$code' gave: $@";
            }
        }
    } else {
        warn ("reimport WARNING: $class->can('import') didn't yield true, ".
              "apparently the module doesn't inherit from Exporter")
          if $verbose;
    }
}


sub ruse {
    @_ > 1 and croak "ruse only takes 0 or 1 arguments";
    local $DEBUG=( @_ ? $_[0] : $DEBUG);
    Chj::ruse::Reload->check;
}

sub import {
    my $caller=caller;#mann ich döbel
    no strict 'refs';
    warn "Copying ruse function to '${caller}::ruse'" if $DEBUG>1;
    *{"${caller}::ruse"}= \&ruse;
}


1
