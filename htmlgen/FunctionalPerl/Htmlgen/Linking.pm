#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::Linking

=head1 SYNOPSIS

=head1 DESCRIPTION

Adding/changing links, currently:

- check whether <code> parts contain things that are either module
  names in our repository or on CPAN, if so link them.

- also, map <code> contents with map_code_body if applicable

- instead of linking non-markdown files locally, make them go to the
  Github repo

=head1 SEE ALSO

These are L<FunctionalPerl::Htmlgen::PXMLMapper>s

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::Linking;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use Sub::Call::Tail;

package FunctionalPerl::Htmlgen::Linking::Anchors {

    # add anchors

    use PXML::XHTML ":all";

    use FP::Struct [] => "FunctionalPerl::Htmlgen::PXMLMapper";

    method match_element_names() { [qw(h1 h2 h3 h4)] }

    method map_element($e, $uplist) {
        my $text = $e->text;
        $text =~ s/ /_/sg;
        A({name => $text}, $e)
    }
    _END_
}

package FunctionalPerl::Htmlgen::Linking::code {
    use FP::List;
    use FP::Predicates;
    use FunctionalPerl::Htmlgen::PathUtil qw(path_diff);
    use PXML::XHTML ":all";
    use Chj::CPAN::ModulePODUrl 'perhaps_module_pod_url';
    use FP::Memoizing 'memoizing_to_dir';

    our $podurl_cache = ".ModulePODUrl-cache";
    mkdir $podurl_cache;
    *xmaybe_module_pod_url = memoizing_to_dir $podurl_cache, sub {
        print STDERR "perhaps_module_pod_url(@_)..";
        my @res = perhaps_module_pod_url @_;
        print STDERR "@res\n";
        wantarray ? @res : $res[-1]
    };

    fun maybe_module_pod_url($v) {
        my $res;
        eval {
            $res = xmaybe_module_pod_url($v);
            1
        } || do {
            my $e         = $@;
            my $firstline = "$e";
            $firstline =~ s/\n.*//s;
            $firstline =~ m/Can't connect/i
                ? do {
                warn "could not look up module '$v': $firstline";
                return undef;
                }
                : die $e
        };
        $res
    }

    # things that *do* exist as modules on CPAN but which we do not want
    # to link since those are a different thing. ("CPAN-exception")
    our $ignore_module_name = +{
        map { $_ => 1 }
            qw(map tail grep fold car cdr first rest head join primes test
            all list Square Point),

        # these are not currently finding anything on CPAN, but let's
        # add them for future safety:
        qw(force length shift F strictlist cons inverse)
    };

    # XX most of those would simply go to local scripts and functions if
    # these were checked for.
    $$ignore_module_name{"X" x 3} = 1;    # avoid tripping search for to-do tags

    fun ignore_module_name($name) {
        $$ignore_module_name{$name}
    }

    use FP::Struct [] => "FunctionalPerl::Htmlgen::PXMLMapper";

    method match_element_names() { ["code"] }

    method map_element($e, $uplist) {

        # possibly *map contents* of inline code or code sections
        my $mapped_e = fun() {
            if (defined(my $f = $self->map_code_body)) {

                # rely on code never containing markup, at least *as long
                # as there's no other mapper that introduced any*. XX how
                # to make sure? (add a xtext method that dies when
                # encountering non-sequence non-string parts?)
                $e->body_set(&$f($e->text, $uplist, $self->path0))
            }
            else {
                $e
            }
        };

        # possibly *wrap* inline code or code sections: add links to
        # '`Foo::Bar`' if found locally or on CPAN. XX perl specific, make
        # addon.
        if (    is_pair $uplist
            and $uplist->first->lcname eq "a"
            and $uplist->first->maybe_attribute("href"))
        {
            # already linked
            &$mapped_e()
        }
        else {
            my $t = $e->text;
            if (is_class_name($t)) {
                my $module_subpath = $t;
                $module_subpath =~ s/::/\//sg;
                $module_subpath .= ".pm";

                my $maybe_path =

                    # XX this should be moved to configuration of course.
                    ($self->maybe_have_path0->("lib/$module_subpath")
                        // $self->maybe_have_path0->("meta/$module_subpath")
                        // $self->maybe_have_path0->("htmlgen/$module_subpath")
                    );

                my $wrap_with_link = sub {
                    my ($url) = @_;
                    A {href => $url}, $e
                };

                my $maybe_cpan_url
                    = ignore_module_name($t) ? undef : maybe_module_pod_url($t);

                if (defined $maybe_cpan_url) {
                    &$wrap_with_link($maybe_cpan_url)
                }
                elsif (defined $maybe_path) {
                    &$wrap_with_link(path_diff $self->path0, $maybe_path)
                }
                else {
                    &$mapped_e()
                }
            }
            else {
                &$mapped_e()
            }
        }
    }
    _END_
}

package FunctionalPerl::Htmlgen::Linking::a_href {
    use FunctionalPerl::Htmlgen::UriUtil qw(URI_is_internal);
    use Chj::xperlfunc qw(dirname);
    use FunctionalPerl::Htmlgen::PathUtil qw(path_add path_diff);
    use FP::Show;

    use FP::Struct [] => "FunctionalPerl::Htmlgen::PXMLMapper";

    method match_element_names() { ["a"] }

    # XX dito config, well all of the map_a_href (also, NOTE the 'XX'
    # comment below about /tree/master instead; well, perhaps
    # configure github repository base url and encode knowhow in the
    # code)
    our $github_base
        = "https://github.com/pflanze/functional-perl/blob/master/";

    method map_element($e, $uplist) {
        if (my ($href) = $e->perhaps_attribute("href")) {

            my $uri = URI->new($href);

            if (URI_is_internal($uri)) {

                # * fix internal .md links

                my $selfpath0 = $self->path0;

                my ($path, $uri, $is_md) = do {    # XX $uri can be
                                                   # unmodified there,
                                                   # right?
                    my $path = $uri->path;

                  # '//' feature (see 'Formatting' section in htmlgen/README.md)
                    if ($href =~ m|^//|s) {
                        my ($op) = $uri->opaque() =~ m|^//([^/].*)$|s
                            or die "bug";
                        $uri->opaque("");          # mutation

                        # Have a lookup hierarchy for the given path,
                        # since the same filename can exist multiple
                        # times. XX: `perhaps_filename_to_path0`
                        # should still be improved to never silently
                        # give wrong results!
                        my $path0_in_samedir = path_add dirname($selfpath0),
                            $op;
                        my $path0_docs = path_add "docs", $op;
                        if (
                            my $p0 =

                            # check as full path from root
                            (
                                $op eq $selfpath0
                                ? undef
                                : $self->maybe_have_path0->($op)
                            )
                            //

                            # check in local dir
                            (
                                $path0_in_samedir eq $selfpath0
                                ? undef
                                : $self->maybe_have_path0->(
                                    $path0_in_samedir)
                            )
                            //

                            # check in docs
                            (
                                $path0_docs eq $selfpath0
                                ? undef
                                : $self->maybe_have_path0->($path0_docs)
                            )
                            //

                            # check as filename anywhere (XX check
                            # against $selfpath0 here, too, or rather,
                            # use this to disambiguate?)
                            $self->perhaps_filename_to_path0->($op)
                            )
                        { (path_diff($selfpath0, $p0), $uri, 1) }
                        else {
                            warn "unknown link target '$op' (from '$href')";
                            (path_diff($selfpath0, "UNKNOWN/$op"), $uri, 1)
                        }
                    }
                    elsif (length $path) {
                        my $p0 = path_add(dirname($selfpath0), $path);
                        $p0 =~ s|^\./||;    #hack. grr y
                        unless ($self->maybe_have_path0->($p0)) {
                            warn "link target does not exist: "
                                . show($p0)
                                . "('$path' from '$selfpath0', link '$href')";

                            #use FP::Repl;repl;
                        }
                        ($path, $uri, $self->pathtranslate->is_md($path))
                    }
                    else { ($path, $uri, $self->pathtranslate->is_md($path)) }
                };

                my $cont_uri = fun($uri) {
                    $e->attribute_set("href", "$uri")
                };
                my $cont_path = fun($path) {
                    $uri->path($self->pathtranslate->possibly_suffix_md_to_html(
                        $path));
                    &$cont_uri($uri);
                };

                if (length $path) {

                    # * change links to non-.md files to go to Github
                    if ($is_md) {
                        &$cont_path($path)
                    }
                    else {
                        if (length(my $p = $uri->path)) {
                            $uri->path(path_add(dirname($self->path0), $p));

                            # XX should use "/tree/master" instead of
                            # "/blob/master" Github url for
                            # directories, but Github redirects anyway
                            # so?
                            &$cont_uri($uri->abs($github_base))

                            # yes, the `path` method is a mutator, `abs` is not!
                        }
                    }
                }
                else {
                    $e
                }

            }
            else {
                $e
            }
        }
        else {
            $e
        }
    }
    _END_
}

1
