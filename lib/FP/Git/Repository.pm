#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Git::Repository

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 SEE ALSO
 
Implements: L<FP::Abstract::Show>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Git::Repository;

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

use FP::Predicates ":all";
use Chj::IO::Command;
use FP::IOStream "fh_to_stream";
use FP::Ops "the_method";
use FP::Combinators "compose";
use Chj::xperlfunc qw(xchdir xexec);
use Chj::singlequote qw(singlequote_many);

our @git = "git";

sub make_perhaps_VAR {
    my ($var, $method) = @_;
    sub {
        my $self = shift;
        if   (defined(my $v = $self->$method)) { ($var => $v) }
        else                                   { () }
    }
}

use FP::Struct [
    [maybe(\&is_nonnullstring), "git_dir"],
    [maybe(\&is_nonnullstring), "work_tree"],
    [maybe(\&is_nonnullstring), "chdir"]
    ],

    # 'FP::Abstract::Pure', can't, setting _git_dir_from_work_tree
    'FP::Struct::Show';

sub git_dir_from_work_tree {
    my $self = shift;
    $$self{_git_dir_from_work_tree} //= do {
        if (defined(my $wd = $self->work_tree)) {
            $wd =~ s|/\z||;
            my $d = "$wd/.git";
            -d $d or die "can't find git_dir from work_tree";
            $d
        } else {
            undef
        }
    }
}

sub git_dir {
    my $self = shift;
    (exists $$self{git_dir} ? $$self{git_dir} : undef)
        // $self->git_dir_from_work_tree
}

*perhaps_GIT_DIR       = make_perhaps_VAR "GIT_DIR",       "git_dir";
*perhaps_GIT_WORK_TREE = make_perhaps_VAR "GIT_WORK_TREE", "work_tree";

sub command_records {
    my $self = shift;
    my ($read, $close, $cmd_and_args) = @_;
    my $in = Chj::IO::Command->new_sender(
        sub {
            if (defined(my $d = $self->chdir)) {
                xchdir $d;
            }
            my $env = { $self->perhaps_GIT_DIR, $self->perhaps_GIT_WORK_TREE };
            for my $var (keys %$env) {
                $ENV{$var} = $$env{$var}
            }
            xexec(@git, @$cmd_and_args);
        }
    );
    fh_to_stream($in, $read, $close)
}

# (Why is SIGPIPE no issue? Well, since git is the process that
# receives it, and *if* it receives it, then it's because we're
# dropping the stream without exhausting it, in which case
# Chj::IO::CommandCommon::DESTROY is called, which closes the
# filehandle and collects the child without complaining.)

sub command_lines {
    my $self = shift;
    $self->command_records(the_method("xreadline"), the_method("xxfinish"),
        [@_])
}

sub command_lines_chomp {
    my $self = shift;
    $self->command_records(the_method("xreadline_chomp"),
        the_method("xxfinish"), [@_])
}

sub command_lines0_chop {
    my $self = shift;
    $self->command_records(the_method("xreadline0_chop"),
        the_method("xxfinish"), [@_])
}

sub perhaps_author_date {
    my $self = shift;
    my $lines
        = $self->command_lines_chomp("log", '--pretty=format:%aD', "--", @_);
    if (is_null $lines) { () }
    else {
        $lines->first
    }
}

sub author_date {
    my $self = shift;
    if (my ($d) = $self->perhaps_author_date(@_)) {
        $d
    } else {
        warn "Note: can't get author date for (file not committed): "
            . singlequote_many(@_) . ".\n";
        ()
    }
}

sub ls_files {
    my $self = shift;
    $self->command_lines0_chop("ls-files", "-z", @_)
}

sub describe {
    my $self = shift;
    $self->command_lines_chomp("describe", @_)->xone
}

sub rev_parse {
    my $self = shift;
    $self->command_lines_chomp("rev-parse", @_)->xone
}

_END_
