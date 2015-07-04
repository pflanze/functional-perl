#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

FP::Git::Repository

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package FP::Git::Repository;

use strict; use warnings FATAL => 'uninitialized';

use FP::Predicates ":all";
use Chj::IO::Command;
use FP::IOStream "fh_to_stream";
use FP::Ops "the_method";
use FP::Combinators "compose";
use Chj::xperlfunc qw(xchdir xexec);

our @git= "git";

sub make_perhaps_VAR {
    my ($var,$method)=@_;
    sub {
	my $self=shift;
	if (defined (my $v= $self->$method)) {
	    ($var=> $v)
	} else {
	    ()
	}
    }
}


use FP::Struct [[maybe(\&is_nonnullstring), "git_dir"],
		[maybe(\&is_nonnullstring), "work_tree"],
		[maybe(\&is_nonnullstring), "chdir"]
	       ];

sub git_dir_from_work_tree {
    my $self=shift;
    $$self{_git_dir_from_work_tree} //= do {
	if (defined (my $wd= $self->work_tree)) {
	    $wd=~ s|/\z||;
	    my $d= "$wd/.git";
	    -d $d or die "can't find git_dir from work_tree";
	    $d
	} else {
	    undef
	}
    }
}

sub git_dir {
    my $self=shift;
    $$self{git_dir} // $self->git_dir_from_work_tree
}


*perhaps_GIT_DIR= make_perhaps_VAR "GIT_DIR", "git_dir";
*perhaps_GIT_WORK_TREE= make_perhaps_VAR "GIT_WORK_TREE", "work_tree";

sub command_records {
    my $self=shift;
    my ($read,$close,$cmd_and_args)=@_;
    my $in= Chj::IO::Command->new_sender
      (sub {
	   if (defined (my $d= $self->chdir)) {
	       xchdir $d;
	   }
	   my $env= {$self->perhaps_GIT_DIR,
		     $self->perhaps_GIT_WORK_TREE};
	   for my $var (keys %$env) {
	       $ENV{$var}= $$env{$var}
	   }
	   xexec(@git, @$cmd_and_args);
       });
    fh_to_stream($in, $read, $close)
}

# XX why is SIGPIPE no issue?

sub command_lines {
    my $self=shift;
    $self->command_records(the_method("xreadline"),
			   the_method("xxfinish"),
			   [@_])
}

sub command_lines_chomp {
    my $self=shift;
    $self->command_records(the_method("xreadline_chomp"),
			   the_method("xxfinish"),
			   [@_])
}

sub command_lines0_chop {
    my $self=shift;
    $self->command_records(the_method("xreadline0_chop"),
			   the_method("xxfinish"),
			   [@_])
}


_END_
