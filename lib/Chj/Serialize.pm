#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Serialize

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::Serialize;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(new_Serialize_Closure);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Chj::TEST;

{
    package Chj::Serializable::Closure;
    use FP::Struct ["env","code_id"],
        'FP::Struct::Show',
        'FP::Abstract::Pure';
    _END_
}


{
    package Chj::Serialize::Closure;

    use PadWalker qw(closed_over set_closed_over);
    use FP::Repl::WithRepl qw(WithRepl_eval);
    use B::Deparse;
    use FP::Predicates ":all";

    our $deparse= B::Deparse->new("-p","-l","-q");

    use FP::Struct [[*is_hash, "_closure_generator_code_to_id"],
                    [*is_hash, "_id_to_closure_generator_code"],
                    [*is_hash, "_id_to_closure_generator"],
                    [*is_natural0, "current_id"]],
        'FP::Struct::Show';

    sub next_id {
        my ($self)=@_;
        $$self{current_id}++
    }

    sub id_to_closure_generator_code {
        my ($self,$id)=@_;
        $$self{_id_to_closure_generator_code}{$id}
          // die "unknown code_id $id";
    }

    sub id_to_closure_generator {
        my ($self,$id)=@_;
        $$self{_id_to_closure_generator}{$id} //=
          &WithRepl_eval ($self->id_to_closure_generator_code ($id))
            // die "eval error: $@";
        #XX oh, want a WithRepl_xeval ?
    }

    sub serializable {
        my ($self,$fn)=@_;

        my $env= closed_over ($fn);
        my $code= $deparse->coderef2text ($fn);

        my $vars= [sort keys %$env];

        my $closure_generator_code=
          'sub { my ('.join(",", @$vars).')=@_; sub '.$code.' }';
        # use this as key right now.

        my $id=
          $$self{_closure_generator_code_to_id}{$closure_generator_code} //= do {
              my $id= $self->next_id;
              $$self{_id_to_closure_generator_code}{$id}=
                $closure_generator_code;
              $id
          };

        # XX exclude web server handle (request) etc. [hw btw in schem? xhu]

        Chj::Serializable::Closure->new($env, $id);
    }

    sub executable {
        my ($self,$serializable_closure)=@_;
        my ($env, $code_id)= ($serializable_closure->env,
                              $serializable_closure->code_id);

        my @vals=
          map {
              $$env{$_}
          }
            sort keys %$env;

        $self->id_to_closure_generator($code_id)->(map {$$_} @vals);
    }

    _END_
}


sub new_Serialize_Closure {
    Chj::Serialize::Closure->new({},{},{},0)
}


my $sc;
my ($sfn, $sfn2);
my $construct;

TEST {
    $sc= new_Serialize_Closure;
    my $hello= "Hello";
    my $unused= "Value";
    $construct=
      sub{
          my ($a,$b)=@_;
          sub {
              my ($x)=@_;
              "$hello $x $a $b"
          }
      };
    $sfn= $sc->serializable
      ($construct->("the", "world", "so"));
}
  bless( {
          'env' => {
                    '$hello' => \'Hello',
                    '$a' => \'the',
                    '$b' => \'world',
                   },
          'code_id' => 0
         }, 'Chj::Serializable::Closure' );


TEST {
    $sfn2= $sc->serializable
      ($construct->("fool", "!"));
}
  bless( {
          'env' => {
                    '$hello' => \'Hello',
                    '$a' => \'fool',
                    '$b' => \'!',
                   },
          'code_id' => 0
         }, 'Chj::Serializable::Closure' );


TEST {
    $sc->executable ($sfn)->("to")
} 'Hello to the world';
TEST {
    $sc->executable ($sfn2)->("you")
} 'Hello you fool !';


1
