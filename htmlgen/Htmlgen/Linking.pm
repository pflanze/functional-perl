#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Htmlgen::Linking

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Htmlgen::PXMLMapper>

=cut


package Htmlgen::Linking;

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

{
    package Htmlgen::Linking::code;

    use FP::List;
    use FP::Predicates;
    use Htmlgen::PathUtil qw(path_diff);
    use PXML::XHTML ":all";

    use Chj::CPAN::ModulePODUrl 'perhaps_module_pod_url';
    our $podurl_cache= ".ModulePODUrl-cache"; mkdir $podurl_cache;
    use FP::Memoizing 'memoizing_to_dir';
    *xmaybe_module_pod_url=
      memoizing_to_dir $podurl_cache, \&perhaps_module_pod_url;

    fun maybe_module_pod_url ($v) {
	my $res;
	eval {
	    $res= xmaybe_module_pod_url ($v);
	    1
	} || do {
	    my $e= $@;
	    my $firstline= "$e"; $firstline=~ s/\n.*//s;
	    $firstline =~ m/Can't connect/i ? do {
		warn "could not look up module '$v': $firstline";
		return undef;
	    }
	      : die $e
	};
	$res
    }


    # things that *do* exist as modules on CPAN but which we do not want
    # to link since those are a different thing.
    our $ignore_module_name=
      +{map {$_=>1}
	qw(map tail grep car cdr first rest head join primes test)};
    # XX most of those would simply go to local scripts and functions if
    # these were checked for.
    $$ignore_module_name{"X"x3}=1; # avoid tripping search for to-do tags

    fun ignore_module_name ($name) {
	$$ignore_module_name{$name}
    }


    use FP::Struct []=> "Htmlgen::PXMLMapper";

    method match_element_name () { "code" }

    method map_element ($e, $uplist) {

	# possibly *map contents* of inline code or code sections
	my $mapped_e= fun () {
	    if (defined (my $f= $self->map_code_body)) {
		# rely on code never containing markup, at least *as long
		# as there's no other mapper that introduced any*. XX how
		# to make sure? (add a xtext method that dies when
		# encountering non-sequence non-string parts?)
		$e->body_set(&$f ($e->text, $uplist, $self->path0))
	    } else {
		$e
	    }
	};

	# possibly *wrap* inline code or code sections: add links to
	# '`Foo::Bar`' if found locally or on CPAN. XX perl specific, make
	# addon.
	if (is_pair $uplist and $uplist->first->lcname eq "a"
	    and $uplist->first->maybe_attribute ("href")) {
	    # already linked
	    &$mapped_e()
	} else {
	    my $t= $e->text;
	    if (is_class_name ($t)) {
		my $module_subpath= $t;
		$module_subpath=~ s/::/\//sg;
		$module_subpath.=".pm";

		my $maybe_path=
		  # XX this should be moved to configuration of course.
		  ($self->maybe_have_path0->("lib/$module_subpath")
		   //
		   $self->maybe_have_path0->("meta/$module_subpath"));

		my $wrap_with_link= sub {
		    my ($url)=@_;
		    A {href=> $url}, $e
		};
		if (defined $maybe_path) {
		    &$wrap_with_link (path_diff $self->path0, $maybe_path)
		} elsif (ignore_module_name $t) {
		    &$mapped_e()
		} elsif (my $url= maybe_module_pod_url ($t)) {
		    &$wrap_with_link ($url)
		} else {
		    &$mapped_e()
		}
	    } else {
		&$mapped_e()
	    }
	}
    }
    _END_
}

{
    package Htmlgen::Linking::a_href;

    use Htmlgen::UriUtil qw(URI_is_internal);
    use Chj::xperlfunc qw(dirname);
    use Htmlgen::PathUtil qw(path_add);

    use FP::Struct []=> "Htmlgen::PXMLMapper";

    method match_element_name () { "a" }

    # XX dito config, well all of the map_a_href
    our $github_base= "https://github.com/pflanze/functional-perl/blob/master/";

    # change links to non-.md files to go to Github
    method map_element ($e, $uplist) {
	if (my ($href)= $e->perhaps_attribute("href")) {
	    if (URI_is_internal(my $u= URI->new($href))) {
		if (length (my $p= $u->path)) {
		    $u->path(path_add (dirname($self->path0), $p));
		    $u= $u->abs($github_base); # yes, path method is
					       # mutator, abs is not!
		    $e->attribute_set("href", "$u")
		} else {
		    $e
		}
	    } else {
		$e
	    }
	} else {
	    $e
	}
    }
    _END_
}


1
