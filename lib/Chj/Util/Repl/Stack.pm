#
# Copyright 2015 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Util::Repl::Stack

=head1 SYNOPSIS

 my $stack= Chj::Util::Repl::Stack->get($numbers_of_levels_to_skip);
 $stack->package($frameno)
 $stack->

=head1 DESCRIPTION

I'm pretty sure this is re-inventing some wheel..

=cut


package Chj::Util::Repl::Stack;

use strict; use warnings FATAL => 'uninitialized';

our @fields; BEGIN { @fields= qw(args
				 package filename line subroutine hasargs
				 wantarray evaltext is_require hints bitmask
				 hinthash) }

{
    package Chj::Util::Repl::StackFrame;
    use Chj::TerseDumper;
    use FP::Div "Chomp";
    use Chj::singlequote qw(singlequote_many with_maxlen);

    use FP::Struct [@fields];

    sub args_text {
	my $s=shift;
	my ($indent)=@_;
	my $args= $s->args;
	my $str= join ",\n", map {
	    # XX reinvention forever, too: how to *shorten*-dump a
	    # value?
	    Chomp (TerseDumper($_))
	} @$args;
	$str= "\n$str" if @$args;
	$str=~ s/\n/\n$indent/g;
	$str
    }

    sub desc {
	my $s=shift;
	($s->subroutine."("
	 .$s->args_text("  ")
	 .")\ncalled at ".$s->filename." line ".$s->line)
    }

    # one-line-desc
    sub oneline {
	my $s=shift;
	my ($maybe_prefix)=@_;
	(($maybe_prefix // "\t") #parens needed!
	 .$s->subroutine
	 ."(".with_maxlen(64, sub{singlequote_many(@{$s->args})}).")"
	 ." called at ".$s->filename." line ".$s->line
	 ."\n")
    }

    _END_
}


sub make_frame_accessor {
    my ($method)= @_;
    sub {
	my $s=shift;
	my ($frameno)=@_;
	my $nf= $s->num_frames;
	$frameno < $nf
	  or die "frame number must be between 0..".($nf-1).", got: $frameno";
	$s->frames->[$frameno]->$method
    }
}


use FP::Struct ["frames"];

sub get {
    my $class=shift;
    my ($skip)=@_;
    package DB;
    my @frames;
    while (my @vals=caller($skip)) {
	my $subargs= [ @DB::args ];
	# XX how to handle this?: "@DB::args might have
	# information from the previous time "caller" was
	# called" (perlfunc on 'caller')
	push @frames, Chj::Util::Repl::StackFrame->new
	  ($subargs, @vals);
	$skip++;
    }
    $class->new(\@frames);
}

sub num_frames {
    my $s=shift;
    scalar @{$s->frames}
}

for (@fields, "desc") {
    no strict 'refs';
    *{$_}= make_frame_accessor $_;
}

sub backtrace {
    my $s=shift;
    my ($maybe_skip)=@_;
    my $skip= $maybe_skip//0;
    my $fs= $s->frames;
    my @f;
    for my $i ($skip..$#$fs) {
	push @f, $$fs[$i]->oneline("$i\t")
    }
    join ("", @f)
}

_END_
