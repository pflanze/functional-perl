#
# Copyright (c) 2014-2021 Christian Jaeger, copying@christianjaeger.ch
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
use experimental "signatures";

use Sub::Call::Tail;

package FunctionalPerl::Htmlgen::Linking::Anchors {

    # add anchors

    use PXML::XHTML ":all";

    use FP::Struct [] => "FunctionalPerl::Htmlgen::PXMLMapper";

    sub match_element_names($self) { [qw(h1 h2 h3 h4)] }

    sub map_element ($self, $e, $uplist) {
        my $text = $e->text;
        $text =~ s/ /_/sg;
        A({ name => $text }, $e)
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
    use FunctionalPerl::Indexing qw(identifierInfos_by_name);
    use FP::Carp;

    our $podurl_cache = ".ModulePODUrl-cache";
    mkdir $podurl_cache;

    # NOTE: ignores are handled further down, see $ignore_module_name
    *xmaybe_module_pod_url = memoizing_to_dir $podurl_cache, sub {
        print STDERR "perhaps_module_pod_url(@_)..";
        my @res = perhaps_module_pod_url @_;
        print STDERR "@res\n";
        wantarray ? @res : $res[-1] ## no critic
    };

    sub maybe_module_pod_url($v) {
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

    sub is_likely_class_name($str) {

        # If $str contains an underscore but no "::" then it's much
        # more likely to be a function or method name than a class
        # name:
        is_valid_class_name($str) and ($str =~ /::/ or not $str =~ /_/)
    }

    use FP::Struct [
        [\&is_string, "functional_perl_base_dir"],
        [\&is_array,  "static_ignore_names"]
    ] => "FunctionalPerl::Htmlgen::PXMLMapper";

    sub _ignore_module_name($self) {
        $self->{_ignore_module_name} //= do {
            my $ignore_module_name
                = identifierInfos_by_name($self->functional_perl_base_dir,
                instance_of("FunctionalPerl::Indexing::Subroutine"));

            for (@{ $self->static_ignore_names }) {
                push @{ $ignore_module_name->{$_} },
                    1;    # that is  not of the same type (Subroutine),
                          # but we just need a boolean.
            }

            # To avoid tripping the search for to-do tags, this isn't part of
            # the list above:
            $$ignore_module_name{ "X" x 3 } = 1;

            $ignore_module_name
        }
    }

    sub ignore_module_name ($self, $name) {
        $self->_ignore_module_name->{$name}
    }

    sub match_element_names($self) { ["code"] }

    sub map_element ($self, $e, $uplist) {

        # possibly *map contents* of inline code or code sections
        my $mapped_e = sub () {
            if (defined(my $f = $self->map_code_body)) {

                # rely on code never containing markup, at least *as long
                # as there's no other mapper that introduced any*. XX how
                # to make sure? (add a xtext method that dies when
                # encountering non-sequence non-string parts?)
                $e->body_set(&$f($e->text, $uplist, $self->path0))
            } else {
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
        } else {
            my $t = $e->text;
            if (is_likely_class_name($t)) {
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
                    A { href => $url }, $e
                };

                my $maybe_cpan_url
                    = $self->ignore_module_name($t)
                    ? undef
                    : maybe_module_pod_url($t);

                if (defined $maybe_cpan_url) {
                    &$wrap_with_link($maybe_cpan_url)
                } elsif (defined $maybe_path) {
                    &$wrap_with_link(path_diff $self->path0, $maybe_path)
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

package FunctionalPerl::Htmlgen::Linking::a_href {
    use FunctionalPerl::Htmlgen::UriUtil qw(URI_is_internal);
    use Chj::xperlfunc qw(dirname);
    use FunctionalPerl::Htmlgen::PathUtil qw(path_add path_diff);
    use FP::Show;

    use FP::Struct [] => "FunctionalPerl::Htmlgen::PXMLMapper";

    sub match_element_names($self) { ["a"] }

    # XX dito config, well all of the map_a_href (also, NOTE the 'XX'
    # comment below about /tree/master instead; well, perhaps
    # configure github repository base url and encode knowhow in the
    # code)
    our $github_base
        = "https://github.com/pflanze/functional-perl/blob/master/";

    sub map_element ($self, $e, $uplist) {
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
                        {
                            (path_diff($selfpath0, $p0), $uri, 1)
                        } else {
                            warn "unknown link target '$op' (from '$href')";
                            (path_diff($selfpath0, "UNKNOWN/$op"), $uri, 1)
                        }
                    } elsif (length $path) {
                        my $p0 = path_add(dirname($selfpath0), $path);
                        $p0 =~ s|^\./||;    #hack. grr y
                        unless ($self->maybe_have_path0->($p0)) {
                            warn "link target does not exist: "
                                . show($p0)
                                . "('$path' from '$selfpath0', link '$href')";

                            #use FP::Repl;repl;
                        }
                        ($path, $uri, $self->pathtranslate->is_md($path))
                    } else {
                        ($path, $uri, $self->pathtranslate->is_md($path))
                    }
                };

                my $cont_uri = sub($uri) {
                    $e->attribute_set("href", "$uri")
                };
                my $cont_path = sub($path) {
                    $uri->path(
                        $self->pathtranslate->possibly_suffix_md_to_html($path)
                    );
                    &$cont_uri($uri);
                };

                if (length $path) {

                    # * change links to non-.md files to go to Github
                    if ($is_md) {
                        &$cont_path($path)
                    } else {
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
