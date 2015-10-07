#
# Copyright 2010 by Christian Jaeger, christian at jaeger mine nu
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::xhome

=head1 SYNOPSIS

=head1 DESCRIPTION

xHOME
just the $HOME env var, dieing if not set, and also checked against a couple assertments

xeffectiveuserhome
just the getpwuid setting

xsafehome
always take xeffectiveuserhome (but asserting that HOME is the same if set)

xhome
take HOME if set (with assertments), otherwise xeffectiveuserhome


=cut


package Chj::xhome;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	   xhome
	  );
@EXPORT_OK=qw(
	      xHOME
	      xeffectiveuserhome
	      xsafehome
	     );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

#our $HOME=

sub xHOME () {
    defined (my $home=$ENV{HOME})
      or die "environment variable HOME is not set";
    length ($home)
      or die "environment variable HOME is the empty string";
    $home
      or die "environment variable HOME is false";
    $home=~ m|^/|
      or die "environment variable HOME does not start with a slash: '$home'";
    $home
}

#sub xrealuserhome () {
#ehr, this is what's interestin right?:
sub xeffectiveuserhome () {
    my $uid= $>;
    my ($name,$passwd,$_uid,$gid,
	$quota,$comment,$gcos,$dir,$shell,$expire)
      = getpwuid $uid
	or die "unknown user for uid $uid";
    $dir
}

sub xsafehome () {
    my $effectiveuserhome= xeffectiveuserhome;
    # basically we well *always* return just that. But check whether,
    # if present, $HOME is consistent:
    if (my $e= $ENV{HOME}) {
	$e eq $effectiveuserhome
	  or die "HOME environment variable is set to something other than the effective user home: '$e' vs. '$effectiveuserhome'";
    }
    $effectiveuserhome
}

sub xhome () {
    # this is probably what *should* be done? use the (fast, was this the purpose unix has introduced it?) HOME setting and if there is none then look it up?
    if ($ENV{HOME}) {
	xHOME
    } else {
	# what about setting HOME in this case?
	xeffectiveuserhome
    }
}


1
