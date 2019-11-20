#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Repl::Stack

=head1 SYNOPSIS

 my $stack= FP::Repl::Stack->get($numbers_of_levels_to_skip);
 my $f= $stack->frame($frameno);
 $f->package
 $f->args
 ...
 # or:
 $stack->package($frameno)
 $stack->args($frameno)
 ...

 # the whole thing as string:
 $stack->backtrace

=head1 DESCRIPTION

I'm pretty sure this is re-inventing some wheel..

=head1 SEE ALSO

L<FP::Repl::StackPlus>

=head1 NOTE

This is alpha software! Read the package README.

=cut


package FP::Repl::Stack;

use strict; use warnings; use warnings FATAL => 'uninitialized';

our @fields; BEGIN { @fields= qw(args
                                 package filename line subroutine hasargs
                                 wantarray evaltext is_require hints bitmask
                                 hinthash) }

{
    package FP::Repl::StackFrame;
    use Chj::TerseDumper;
    use FP::Div "Chomp";
    use Chj::singlequote qw(singlequote_many with_maxlen);
    use FP::Show;

    use FP::Struct [@fields];

    sub args_text {
        my $s=shift;
        my ($indent, $mode)=@_;
        my $args= $s->args;
        my $str= join ",\n", map {
            if ($mode eq "d") {
                # XX reinvention forever, too: how to *shorten*-dump a
                # value? Data::Dumper does not seem to support it?
                local $Data::Dumper::Maxdepth= 1;
                # ^ ok helps a bit sometimes. XX But will now be
                # confusing, as there's no way to know references from
                # (accidentally) stringified references
                Chomp (TerseDumper($_))
            } elsif ($mode eq "s") {
                show($_)
            } elsif ($mode eq "p") {
                "$_"
            } else {
                die "unknown mode '$mode'";
            }
        } @$args;
        $str= "\n$str" if @$args;
        $str=~ s/\n/\n$indent/g; # XX there's also $Data::Dumper::Pad
        $str
    }

    sub desc {
        my ($s,$mode)=@_;
        ($s->subroutine."("
         .$s->args_text("  ", $mode)
         ."\n) called at ".$s->filename." line ".$s->line)
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

    # CAREFUL: equal stackframes still don't need to be the *same*
    # stackframe!
    sub equal {
        my $s=shift;
        my ($v)=@_;
        my $equal_standard_fields= sub {
            my $eq= sub {
                my ($m)=@_;
                #$s->$m eq $v->$m
                my $S= $s->$m;
                my $V= $v->$m;
                if (defined $S) {
                    if (defined $V) {
                        $S eq $V
                    } else {
                        0
                    }
                } else {
                    if (defined $V) {
                        0
                    } else {
                        1 # both undefined
                    }
                }
            };
            (&$eq ("package")
             and
             &$eq ("filename")
             and
             &$eq ("line")
             and
             &$eq ("subroutine")
             and
             &$eq ("hasargs")
             and
             &$eq ("wantarray")
             #and
             #&$eq ("")
             # hints bitmask hinthash ?
            )
        };
        if (defined $v->args) {
            if (defined $s->args) {
                (&$equal_standard_fields
                 and do {
                     require FP::DumperEqual;
                     FP::DumperEqual::dumperequal ($v->args, $s->args)
                 })
            } else {
                ''
            }
        } else {
            if (defined $s->args) {
                ''
            } else {
                &$equal_standard_fields
            }
        }
    }

    _END_
}


our $make_frame_accessor= sub {
    my ($method)= @_;
    sub {
        my $s=shift;
        my ($frameno,@rest)=@_;
        my $nf= $s->num_frames;
        $frameno < $nf
          or die "frame number must be between 0..".($nf-1).", got: $frameno";
        $s->frames->[$frameno]->$method(@rest)
    }
};

our $make_perhaps_frame_accessor= sub {
    my ($method)= @_;
    sub {
        my $s=shift;
        my ($frameno,@rest)=@_;
        my $nf= $s->num_frames;
        ($frameno < $nf
         ? ($s->frames->[$frameno]->$method(@rest))
         : ())
    }
};


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
        push @frames, FP::Repl::StackFrame->new
          ($subargs, @vals);
        $skip++;
    }
    $class->new(\@frames);
}

sub frame {
    my $s=shift;
    @_==1 or die "wrong number of arguments";
    my ($i)=@_;
    $s->frames->[$i]
}

sub num_frames {
    my $s=shift;
    scalar @{$s->frames}
}

sub max_frameno {
    my $s=shift;
    $#{$s->frames}
}

for (@fields, "desc") {
    no strict 'refs';
    *{$_}= &$make_frame_accessor ($_);
    *{"perhaps_$_"}= &$make_perhaps_frame_accessor ($_);
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
