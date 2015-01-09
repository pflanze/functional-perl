#
# Copyright 2006-2014 by Christian Jaeger, ch at christianjaeger . ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Package::OfPath

=head1 SYNOPSIS

=head1 DESCRIPTION

(Taken from chj-bin's perl_path2namespace.)


=cut


package Chj::Package::OfPath;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      package_of_path
	      package_of_path_or_package
	     );

use strict;
use Cwd 'abs_path';
use Chj::singlequote;

our $DEBUG=0;

sub package_of_path {
    my ($path)=@_;
    $path=~ s{^\./}{};
    my $class= $path;
    $class=~ s/\.pm$//;
    $class=~ s|/|::|sg;
    if ($path=~ m{^/}) {
	# absolute
    } else {
	my $p= abs_path $path
	  or die "abs_path '$path': $!";
	$path= $p;
    }
    warn "path=".singlequote($path) if $DEBUG;

    open IN,"<$path"
      or die "could not open '$path': $!";

    local $/;
	my $content= <IN>;
    close IN
      or die "closing '$path': $!";
  CHECK: {
	while ($content=~ m{\bpackage +([\w:]+)}g) {
	    my $namespace= $1;
	    if ($class=~ m/\Q$namespace\E$/) {
		warn "cutting '$class' down to '$namespace'\n" if $DEBUG;
		$class= $namespace;
		last CHECK;
	    }
	}
	die "could not find any package definition in '$path' ".
	  "matching its path";
    }
    $class
}

sub package_of_path_or_package {
    my ($path_or_package)=@_;
    if ($path_or_package=~ m{(\S+\.pm)}) {
	package_of_path($1)
    } elsif ($path_or_package=~ m{^(\w+\:\:)*\w+\z}s) {
	$path_or_package
    } elsif ($path_or_package=~ m{^(\w+/)*\w+\z}s) {
	$path_or_package=~ s|/|::|sg;
	$path_or_package
    } else {
	die "doesn't look sane: ".singlequote($path_or_package)
    }
}

1
