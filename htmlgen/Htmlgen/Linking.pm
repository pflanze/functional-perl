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

Adding/changing links, currently:

- check whether <code> parts contain things that are either module
  names in our repository or on CPAN, if so link them.

- also, map <code> contents with map_code_body if applicable

- instead of linking non-markdown files locally, make them go to the
  Github repo

=head1 SEE ALSO

This is a L<Htmlgen::PXMLMapper>

=cut


package Htmlgen::Linking;

use strict; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;


{
    package Htmlgen::Linking::Anchors;
    # add anchors

    use PXML::XHTML ":all";

    use FP::Struct []=> "Htmlgen::PXMLMapper";

    method match_element_names () { [qw(h1 h2 h3 h4)] }

    method map_element ($e, $uplist) {
	my $text= $e->text;
	$text=~ s/ /_/sg;
	A({name=> $text}, $e)
    }
    _END_
}


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

    method match_element_names () { [ "code" ] }

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
		   $self->maybe_have_path0->("meta/$module_subpath")
		   //
		   $self->maybe_have_path0->("htmlgen/$module_subpath"));

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
    use Htmlgen::PathUtil qw(path_add path_diff);

    use FP::Struct []=> "Htmlgen::PXMLMapper";

    method match_element_names () { ["a"] }

    # XX dito config, well all of the map_a_href (also, NOTE the 'XX'
    # comment below about /tree/master instead; well, perhaps
    # configure github repository base url and encode knowhow in the
    # code)
    our $github_base= "https://github.com/pflanze/functional-perl/blob/master/";

    method map_element ($e, $uplist) {
	if (my ($href)= $e->perhaps_attribute("href")) {

	    my $uri= URI->new($href);

	    if (URI_is_internal($uri)) {

		# * fix internal .md links

		my $selfpath0= $self->path0;

		my ($path,$uri,$is_md)= do { # XX $uri can be unmodified there, right?
		    my $path= $uri->path;

		    # '//' feature (see 'Formatting' section in htmlgen/README.md)
		    if ($href =~ m|^//|s) {
			my ($op)= $uri->opaque() =~ m|^//([^/]+)$|s
			  or die "bug";
			$uri->opaque(""); # mutation

			if (my ($p0)= $self->perhaps_filename_to_path0->($op)) {
			    (path_diff ($selfpath0,$p0), $uri, 1)
			} else {
			    warn "unknown link target '$op' (from '$href')";
			    (path_diff ($selfpath0, "UNKNOWN/$op"), $uri, 1)
			}
		    }
		    elsif (length $path) {
			my $p0= path_add(dirname ($selfpath0), $path);
			$p0=~ s|^\./||;#hack. grr y
			unless ($self->maybe_have_path0->($p0)) {
			    warn "link target does not exist: '$p0' ".
			      "('$path' from '$selfpath0', link '$href')";
			    #use Chj::repl;repl;
			}
			($path, $uri, $self->pathtranslate->is_md($path))
		    }
		    else {
			($path, $uri, $self->pathtranslate->is_md($path))
		    }
		};

		my $cont_uri= fun ($uri) {
		    $e->attribute_set("href", "$uri")
		};
		my $cont_path= fun ($path) {
		    $uri->path($self->pathtranslate->possibly_suffix_md_to_html ($path));
		    &$cont_uri($uri);
		};

		if (length $path) {
		    # * change links to non-.md files to go to Github
		    if ($is_md) {
			&$cont_path($path)
		    } else {
			if (length (my $p= $uri->path)) {
			    $uri->path(path_add (dirname($self->path0), $p));
			    # XX should use "/tree/master" instead of
			    # "/blob/master" Github url for
			    # directories, but Github redirects anyway
			    # so?
			    &$cont_uri($uri->abs($github_base))
			      # yes, the `path` method is a mutator, `abs` is not!
			}
		    }
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
