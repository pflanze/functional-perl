#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Indexing -- retrieve information about the code base

=head1 SYNOPSIS

    use FunctionalPerl::Indexing qw(
        identifierInfos_by_name Subroutine Package);
    use FP::Equal qw(is_equal);

    my $functional_perl_base_dir = ".";
    my $by_name = identifierInfos_by_name(
        $functional_perl_base_dir,
        # accept all of them:
        sub ($info) { 1 });
    is_equal($by_name->{first}->[0],
             Subroutine('first', 'lib/FP/Array/Mixin.pm', 153));
    is_equal($by_name->{"FP::List"}->[0],
             Package('FP::List', 'lib/FP/List.pm', 127, ''));

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Indexing;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
no warnings 'shadow';
use Exporter "import";

our @EXPORT      = qw();
our @EXPORT_OK   = qw(identifierInfos_by_name Subroutine Package);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use File::chdir;    # qw($CWD) nope, can't request it explicitly.
use Chj::xopen qw(xopen_read);
use Chj::IO::Command;
use FP::Docstring;
use FP::Predicates qw(is_defined $package_re);
use FP::PureArray;
use Chj::xopen qw(xopen_read);
use FP::IOStream qw(xfile_lines);
use FP::Lazy;
use Digest::MD5 qw(md5_hex);

use Chj::TEST ":all";

# ------------------------------------------------------------------

package FunctionalPerl::Indexing::IdentifierInfo {
    use FP::Struct ["name", "file", "lineno"] =>
        ("FP::Struct::Show", "FP::Struct::Equal");
    _END_
}

package FunctionalPerl::Indexing::Subroutine {
    use FP::Struct [] => "FunctionalPerl::Indexing::IdentifierInfo";
    _END_
}
FunctionalPerl::Indexing::Subroutine::constructors->import;

package FunctionalPerl::Indexing::Package {
    use Chj::Packages qw(xrequire_package_by_path);
    use FP::Docstring;

    use FP::Struct ["is_newstyle"] =>
        "FunctionalPerl::Indexing::IdentifierInfo";

    sub package_type ($self) {
        __ 'Return "exporter" if it can export things via "use", or
            "class" otherwise.  This loads the package to get access
            to is variables at runtime!';
        $self->{_package_type} //= do {
            xrequire_package_by_path $self->file;
            no strict 'refs';
            my $stash = \%{ $self->{name} . "::" };

            # (`|| []` might not be needed, as I didn't get an error
            # in my tests, but oddly it is needed for EXPORT.)
            my %isa = map { $_ => 1 } @{ $stash->{ISA} || [] };
            if ($isa{Exporter}) {
                "exporter"
            } elsif (exists $stash->{EXPORT}
                or exists $stash->{EXPORT_OK}
                or exists $stash->{EXPORT_TAGS})
            {
                "exporter"
            } elsif (exists $stash->{import}) {

                # warn "non Exporter kind of exporter";
                "exporter"
            } else {
                "class"
            }
        }
    }
    _END_
}
FunctionalPerl::Indexing::Package::constructors->import;

TEST { Package("FP::List", "lib/FP/List.pm", 123)->package_type } 'exporter';
TEST { Package("FP::List::List", "lib/FP/List.pm", 123)->package_type } 'class';
TEST { Package("FP::List::Pair", "lib/FP/List.pm", 123)->package_type } 'class';
TEST { Package("Chj::TEST", "lib/Chj/TEST.pm", 123)->package_type } 'exporter';
TEST { Package("PXML::Tags", "lib/PXML/Tags.pm", 123)->package_type }
'exporter';
TEST {
    Package("FP::Abstract::Sequence", "lib/FP/Abstract/Sequence.pm", 123)
        ->package_type
}
'class';    # might change?

my $var_re = qr/[a-zA-Z_]\w*/;

sub file_IdentifierInfos ($path) {

    #my $lines = xfile_lines($path)->purearray;

    # Not using xfile_lines makes user time go down from 0m1.096s to
    # 0m0.336s. XX do something about it...
    my $lines = do {
        my $in    = xopen_read($path);
        my $lines = purearray $in->xreadline;
        $in->xclose;
        $lines
    };

    $lines->map_with_index(
        sub ($i, $line) {
            my $lineno = $i + 1;
            if (my ($pre, $name) = $line =~ /^(.*?)\bsub ($var_re)/) {
                if ($pre =~ /["']/ or $pre =~ /\bq\b/) {
                    undef
                } else {
                    Subroutine($name, $path, $lineno)
                }
            } elsif (my ($name) = $line =~ /^\s*\*\s*($var_re)\s*=/) {

                # The setting of a glob. *Assume* that it's for a code
                # ref. XX improve?
                Subroutine($name, $path, $lineno)
            } elsif (my ($name, $post)
                = $line =~ /package\s+($package_re)\s*(;|\{)/)
            {
                Package($name, $path, $lineno, $post eq '{')
            } else {
                undef
            }
        }
    )->filter(\&is_defined)
}

sub files_IdentifierInfos_by_name ($files, $acceptableP) {
    __ 'Sequence of file paths -> +{name => [IdentifierInfo...]}';
    my %by_name;
    $files->map(\&file_IdentifierInfos)->for_each(
        sub ($infos) {
            $infos->filter($acceptableP)->for_each(
                sub ($info) {
                    push @{ $by_name{ $info->name } }, $info;
                }
            );
        }
    );
    \%by_name
}

sub perlfiles() {
    my $newsum = md5_hex(xopen_read("MANIFEST")->xcontent);
    my $in     = xopen_read(".perlfiles");
    my $oldsum = $in->xreadline;
    chomp $oldsum;
    if ($newsum ne $oldsum) {
        die ".perlfiles is outdated; please run, in the Git checkout, "
            . "with chj-scripts installed (you're meant to be the maintainer):\n"
            . "  meta/perlfiles \n ";
    }
    my @perlfiles = $in->xreadline;
    $in->xclose;
    chomp @perlfiles;
    purearray @perlfiles
}

sub identifierInfos_by_name ($functional_perl_base_dir, $acceptableP) {
    __ '(Path to functional-perl base directory, $acceptableP) ->
        +{name => [IdentifierInfo...]}; $acceptableP is a predicate
        returning true for those instances you want.';
    local $CWD = $functional_perl_base_dir;

    # Ignore files that can't be used for imports and aren't examples, OK?
    my $files
        = perlfiles->filter(sub ($v) { $v =~ /\.pm$/ or $v =~ /^examples\// });
    files_IdentifierInfos_by_name $files, $acceptableP
}

# for tests only:
my $by_name = lazy {
    identifierInfos_by_name ".", sub($v) {1}
};

sub scrubline {
    my ($ary) = @_;
    [map { $_->lineno_set(123) } @$ary]
}

sub t {
    scrubline force($by_name)->{ $_[0] }
}

TEST { t "car" } [
    Subroutine('car', 'lib/FP/List.pm', 123),
    Subroutine('car', 'lib/FP/List.pm', 123)
];
TEST { t "first" }
[
    Subroutine('first', 'lib/FP/Array/Mixin.pm', 123),
    Subroutine('first', 'lib/FP/List.pm',        123),
    Subroutine('first', 'lib/FP/List.pm',        123),
    Subroutine('first', 'lib/FP/List.pm',        123),
    Subroutine('first', 'lib/FP/List.pm',        123)
];
TEST { t "FP::List" }
[Package('FP::List', 'lib/FP/List.pm', 123, '')];
TEST { t "FP::List::Pair" } [
    Package('FP::List::Pair', 'lib/FP/List.pm', 123, 1),
    Package('FP::List::Pair', 'lib/FP/List.pm', 123, 1)
];

# ------------------------------------------------------------------

# If you wanted to get methods from interfaces:

# (Which would only be worthwhile for generating the HTML crosslinking
# thing, since for just the names, all methods will exist as sub or *
# definitions and be picked up anyway.)

# sub all_abstract_files() {
#     glob "lib/FP/Abstract/*pm"
# }
# no, better access from the index!:

TEST { t "FP_Interface__method_names" } [
    Subroutine('FP_Interface__method_names', 'lib/FP/Abstract/Compare.pm', 123),
    Subroutine('FP_Interface__method_names', 'lib/FP/Abstract/Equal.pm',   123),
    Subroutine('FP_Interface__method_names', 'lib/FP/Abstract/Id.pm',      123),
    Subroutine(
        'FP_Interface__method_names', 'lib/FP/Abstract/Interface.pm', 123
    ),
    Subroutine('FP_Interface__method_names', 'lib/FP/Abstract/Map.pm',  123),
    Subroutine('FP_Interface__method_names', 'lib/FP/Abstract/Pure.pm', 123),
    Subroutine(
        'FP_Interface__method_names', 'lib/FP/Abstract/Sequence.pm', 123
    ),
    Subroutine('FP_Interface__method_names', 'lib/FP/Abstract/Show.pm', 123),
    Subroutine('FP_Interface__method_names', 'lib/FP/Interface.pm',     123),
    Subroutine('FP_Interface__method_names', 'lib/FP/Interface.pm',     123)
];

1
