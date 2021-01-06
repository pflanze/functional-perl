#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::PathTranslate

=head1 SYNOPSIS

=head1 DESCRIPTION

Configurable source path (.md suffix) to website path (.xhtml suffix
or similar, index instead of README etc.) mapper.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::PathTranslate;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";

use Sub::Call::Tail;
use Chj::TEST;
use FP::Predicates;
use Chj::xperlfunc qw(dirname basename);
use FunctionalPerl::Htmlgen::PathUtil qw(path_path0_append);
use FP::Div qw(identity);
use FunctionalPerl::Htmlgen::default_config;
use FP::Show;
use FP::Predicates 'false';

our $t = __PACKAGE__->new_(
    is_indexpath0 => $$default_config{is_indexpath0},
    downcaps      => 1
);

sub t_if_suffix_md_to_html ($in, $for_title = 0) {
    $t->if_suffix_md_to_html(
        $in, $for_title,
        sub { ["then",      @_] },
        sub { ["otherwise", @_] }
    )
}

sub is_allcaps($str) {
    not $str =~ /[a-z]/
}

sub _path0_to_title_mod($str) {
    $str =~ s/_/ /sg;
    ucfirst $str
}

# ------------------------------------------------------------------

use FP::Struct [[\&is_procedure, "is_indexpath0"], [*is_boolean, "downcaps"],];

sub is_md ($self, $path) {
    $path =~ /\.md$/s
}

sub if_suffix_md_to_html ($self, $path0, $for_title, $then, $otherwise) {
    if (!$for_title and $$self{is_indexpath0}->($path0)) {
        tail &$then(path_path0_append(dirname($path0), "index.xhtml"))
    } else {
        if ($path0 =~ s/(.*?)([^\/]*)\.md$/$1$2.xhtml/) {
            tail &$then($$self{downcaps}
                    && is_allcaps($2) ? $1 . lc($2) . ".xhtml" : $path0);
        } else {
            tail &$otherwise($path0)
        }
    }
}

TEST { t_if_suffix_md_to_html "README.md" }['then', 'index.xhtml'];
TEST { t_if_suffix_md_to_html "README.md", 1 }['then', 'readme.xhtml'];

# ^ kinda stupid hack.
TEST { t_if_suffix_md_to_html "Foo/index.md" }['then', 'Foo/index.xhtml'];
TEST { t_if_suffix_md_to_html "Foo/README.md" }['then', 'Foo/index.xhtml'];
TEST { t_if_suffix_md_to_html "Foo/READMe.md" }['then', 'Foo/index.xhtml'];

# ^ XX really?
TEST { t_if_suffix_md_to_html "Foo/MY.css" }['otherwise', 'Foo/MY.css'];

sub possibly_suffix_md_to_html ($self, $path, $for_title = 0) {
    $self->if_suffix_md_to_html($path, $for_title, \&identity, \&identity)
}

sub xsuffix_md_to_html ($self, $path0, $for_title) {
    $self->if_suffix_md_to_html($path0, $for_title, \&identity,
        sub { die "file does not end in .md: " . show($path0) })
}

TEST { $t->possibly_suffix_md_to_html("foo") } "foo";
TEST { $t->possibly_suffix_md_to_html("foo.md") } "foo.xhtml";
TEST_EXCEPTION { $t->xsuffix_md_to_html("foo", 0) }
"file does not end in .md: 'foo'";

sub path0_to_title ($self, $path0) {
    my $dn = dirname($path0);
    if ($dn ne "." and $$self{is_indexpath0}->($path0)) {
        _path0_to_title_mod basename($self->xsuffix_md_to_html($dn . ".md", 1),
            ".xhtml");
    } else {
        _path0_to_title_mod basename($self->xsuffix_md_to_html($path0, 1),
            ".xhtml");
    }
}

TEST { $t->path0_to_title("README.md") } 'Readme';
TEST { $t->path0_to_title("bugs/wishlist/listserv/index.md") } 'Listserv';
TEST { $t->path0_to_title("bugs/wishlist/listserv/README.md") } 'Listserv';
TEST { $t->path0_to_title("bugs/wishlist/listserv/other.md") } 'Other';

TEST {
    $t->is_indexpath0_set(\&false)
        ->path0_to_title("bugs/wishlist/listserv/README.md")
}
'Readme';
TEST { $t->path0_to_title("bugs/wishlist/line_wrapping_in_pre-MIME_mails.md") }

# even with lcfirst
'Line wrapping in pre-MIME mails';

sub path0_to_bugtype ($self, $path0) {
    $path0 =~ m|\bbugs/([^/]+)/| or die "no match, '$path0'";
    ucfirst $1
}

_END_
