#
# Copyright (c) 2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::AST::Perl -- abstract syntax tree for representing Perl code

=head1 SYNOPSIS

    use FP::AST::Perl ":all";
    use FP::List; use FP::Equal ":all";

    is Get(LexVar('foo'))->string, '$foo';
    is Get(PackVarScalar "foo")->string, '$foo';
    is Get(PackVarArray "foo")->string, '@foo';
    is Get(PackVarHash "foo::bar")->string, '%foo::bar';

    my $codefoo= PackVarCode("foo");
    my $arrayfoo= PackVarArray("foo");
    my $lexfoo= LexVar("foo");
    is App(Get($codefoo), list())->string,
       '&foo()';
    is AppProto(Get($codefoo), list())->string,
       'foo()';
    is AppProto(Get($lexfoo), list(Ref($codefoo)))->string,
       '$foo->(\&foo)';
    is AppProto(Get($lexfoo), list(Get($lexfoo), Get($arrayfoo), Ref($arrayfoo)))->string,
       '$foo->($foo, @foo, \@foo)';
    is AppProto(Get($codefoo), list(Get(LexVar 'foo'), Literal(Number 123)))->string,
       'foo($foo, 123)';
    is AppProto(Get($codefoo), list(Get($lexfoo), Literal(String 123)))->string,
       'foo($foo, \'123\')';

    is_equal semicolons(), Noop;
    is_equal semicolons(Noop), Noop;
    is_equal semicolons(Noop, Noop, Noop),
             Semicolon(Noop(), Semicolon(Noop(), Noop()));
    is semicolons(Noop, Noop, Noop)->string, '; ; ';

    is Let(list(LexVar("foo"), LexVar("bar")),
           Get(PackVarArray "baz"),
           semicolons(
               AppProto(Get(PackVarCode "print"),
                        list Literal String "Hello"),
               Get(LexVar("bar"))))->string,
       'my ($foo, $bar) = @baz; print(\'Hello\'); $bar';
    # Yes, how should print, map etc. be handled?


=head1 DESCRIPTION

This is not a parser, and hence should be outside the scope of the
"can only parse Perl at runtime" issue.

The longer term aim is to support all of Perl, and to support
conversion to and maybe from an op tree.

=head1 SEE ALSO

Implements: L<FP::Abstract::Pure>, L<FP::Abstract::Show>,
L<FP::Abstract::Equal>.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::AST::Perl;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
my @classes=qw(
    LexVar PackVarScalar PackVarCode PackVarHash PackVarArray PackVarGlob
    App AppProto Get Ref
    Number String
    Literal
    Semicolon Noop Let);
@EXPORT_OK=(
    @classes, qw(
    is_packvar_type
    is_var
    is_lexvar is_packvar
    is_expr is_nonnoop_expr is_noop
    semicolons));

%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Function::Parameters qw(:strict);
use FP::Predicates ":all";
use Chj::TEST;
use FP::List;

# import the constructors of the classes defined below
for my $name (@classes) {
    "FP::AST::Perl::${name}::constructors"->import()
}


package FP::AST::_::Perl {
    use FP::Docstring;

    use FP::Struct [] =>
        "FP::Abstract::Pure",
        "FP::Struct::Equal",
        "FP::Struct::Show";

    method string_proto () {
        __  "stringification when used as the callee in AppProto";
        $self->string
    }

    _END_
}


# Variables

package FP::AST::Perl::Var {
    use FP::Predicates ":all";
    
    use FP::Struct [
        ]=> "FP::AST::_::Perl";

    method string () {
        $self->sigil . $self->name
    }

    _END_
}

*is_var= instance_of "FP::AST::Perl::Var"; ## XX Are those not all auto generated MAN ???


# XX move to FP::Predicates? Or FP::Parser::Perl ?
sub is_lexvar_string ($) {
    my ($str)=@_;
    $str=~ /^\w+\z/
}

package FP::AST::Perl::LexVar {
    use FP::Predicates ":all";
    
    use FP::Struct [
        [*FP::AST::Perl::is_lexvar_string, 'name']
        ] => "FP::AST::Perl::Var";

    method sigil () { '$' }
    method callderef () { '->' }

    _END_
}

*is_lexvar= instance_of "FP::AST::Perl::LexVar";


package FP::AST::Perl::PackVar {
    use FP::Predicates ":all";
    
    use FP::Struct [
        [*is_string, 'name'],
        # ^ XX is_package_name ? But isn't everything allowed? But
        # then todo proper printing
        ] => "FP::AST::Perl::Var";
    method callderef () { die $self->type_name." can't be called" }
    _END_
}

*is_packvar= instance_of "FP::AST::Perl::PackVar";

package FP::AST::Perl::PackVarScalar {
    use FP::Struct [] => "FP::AST::Perl::PackVar";
    method type_name () { "SCALAR" }
    method sigil () { '$' }
    method callderef () { '->' }
    _END_
}
package FP::AST::Perl::PackVarCode {
    use FP::Struct [] => "FP::AST::Perl::PackVar";
    method type_name () { "CODE" }
    method sigil () { '&' }
    method callderef () { '' }

    method string_proto () { $self->name }
    _END_
}
package FP::AST::Perl::PackVarHash {
    use FP::Struct [] => "FP::AST::Perl::PackVar";
    method type_name () { "HASH" }
    method sigil () { '%' }
    _END_
}
package FP::AST::Perl::PackVarArray {
    use FP::Struct [] => "FP::AST::Perl::PackVar";
    method type_name () { "ARRAY" }
    method sigil () { '@' }
    _END_
}
package FP::AST::Perl::PackVarGlob { # XX *?*
    use FP::Struct [] => "FP::AST::Perl::PackVar";
    method type_name () { "GLOB" }
    method sigil () { '*' }
    _END_
}



# Expressions

package FP::AST::Perl::Expr {

    use FP::Struct [] => "FP::AST::_::Perl";
    
    _END_
}

*is_expr= instance_of "FP::AST::Perl::Expr";
*is_nonnoop_expr= both *is_expr, complement *is_noop;

# Do we need to distinguish context (list vs. scalar [vs. void]),
# really? No, since the *dynamic* context determines this!

package FP::AST::Perl::Get {
    use FP::Predicates ":all";
    
    use FP::Struct [
        [*FP::AST::Perl::is_var, 'var'],
        ] => "FP::AST::Perl::Expr";

    # XX problem is, for CODE vars, Get is only valid in App proc
    # context! Otherwise, Ref must be used! How to type check?
    # Different methods than just string I guess!!

    # XX BTW eliminate those delegates? Just call manually? OR: use
    # Var directly in App proc ??
    
    method string () {
        $self->var->string
    }

    method string_proto () {
        $self->var->string_proto
    }

    method callderef () {
        $self->var->callderef
    }
    
    _END_
}

# Take referenceS, 'instead of just Get-ing the valueS':

package FP::AST::Perl::Ref {
    use FP::Predicates ":all";
    
    use FP::Struct [
        [*FP::AST::Perl::is_var, 'var'],
        ] => "FP::AST::Perl::Expr";

    method string () {
        "\\" . $self->var->string
    }

    # method string_proto () {
    #     # $self->var->string_proto
    #     #die "there is no prototype call with a ref expression"
    #         # ok? or just omit and let it fall back to ->string ? but
    #         # i DO think this call should never happen, right?
    # }

    method callderef () {
        # taking a ref means the call will have to deref it, always
        '->'
    }
    
    _END_
}

# *is_ref= instance_of "FP::AST::Perl::Ref";

package FP::AST::Perl::App {
    use FP::Predicates ":all";
    use FP::List ":all";
    use FP::Ops ":all";
    
    use FP::Struct [
        [*FP::AST::Perl::is_expr, 'proc'],
        [list_of *FP::AST::Perl::is_expr, 'argexprs'],
        # ^ yes, proc is also an expr, but only yielding one (usable)
        # value, as opposed to argexprs which may yield more used
        # values than there are exprs (at least here; not
        # (necessarily) in AppProto).
        ] => "FP::AST::Perl::Expr";

    method string () {
        $self->proc_string . $self->proc->callderef . "(" .
            $self->argexprs->map(the_method "string")->strings_join (", ") .
            # ^ XX are parens needed around arguments?
            ")"
    }
    method proc_string () {
        $self->proc->string
    }
    _END_
}

package FP::AST::Perl::AppProto {
    # App with exposure to prototypes
    use FP::Struct [
        ] => "FP::AST::Perl::App";

    method proc_string () {
        $self->proc->string_proto
    }

    _END_
}


# Literals

package FP::AST::Perl::Value {
    use FP::Predicates ":all";
    
    use FP::Struct [
        ] => "FP::AST::_::Perl";

    # missing string method  XX interface
    
    _END_
}

*is_value= instance_of "FP::AST::Perl::Value";

package FP::AST::Perl::Number {
    use FP::Predicates ":all";
    use Scalar::Util qw(looks_like_number);

    use FP::Struct [
        [*looks_like_number, 'perlvalue'],
        ] => "FP::AST::Perl::Value";

    method string () {
        $self->perlvalue # no quoting
    }

    _END_
}

package FP::AST::Perl::String {
    use FP::Predicates ":all";
    use Chj::singlequote;

    use FP::Struct [
        'perlvalue',
        ] => "FP::AST::Perl::Value";

    method string () {
        singlequote($self->perlvalue)
    }

    _END_
}


package FP::AST::Perl::Literal {
    use FP::Predicates ":all";
    use FP::List ":all";
    use FP::Ops ":all";
    
    use FP::Struct [
        [*FP::AST::Perl::is_value, 'value'],
        ] => "FP::AST::Perl::Expr";

    method string () {
        $self->value->string
    }

    _END_
}


package FP::AST::Perl::Semicolon {
    use FP::Struct [
        [*FP::AST::Perl::is_expr, 'a'],
        [*FP::AST::Perl::is_expr, 'b'],
        ] => "FP::AST::Perl::Expr";

    method string () {
        $self->a->string . "; " . $self->b->string
    }
    _END_
}

package FP::AST::Perl::Noop {
    use FP::Struct [
        ] => "FP::AST::Perl::Expr";

    method string () {
        ""
    }
    _END_
}

*is_noop= instance_of "FP::AST::Perl::Noop";

sub semicolons {
    @_ ? do {
        my ($a, $r)= list(@_)->reverse->first_and_rest;
        $r->fold(*Semicolon, $a)
    } : Noop()
}


package FP::AST::Perl::Let {
    use FP::Predicates;
    use FP::List;
    use FP::Ops ":all";

    use FP::Struct [
        [list_of *FP::AST::Perl::is_var, 'vars'],
        [*FP::AST::Perl::is_nonnoop_expr, 'expr'],
        [*FP::AST::Perl::is_expr, 'body'],
        ] => "FP::AST::Perl::Expr";

    method string () {
        my $vars= $self->vars;
        my $multiple= $vars->length > 1;
        "my "
            . ($multiple ? "(" : "")
            . $vars->map(the_method "string")->strings_join(", ")
            . ($multiple ? ")" : "")
            . " = "
            . $self->expr->string
            . "; " # XX like Semicolon! But not the same *?* Q
            . $self->body->string
    }
    _END_
}


TEST_EXCEPTION {
    LexVar('foo::bar')
} 'unacceptable value for field \'name\': \'foo::bar\'';

sub String;
sub Literal;
sub PackVarArray;
sub PackVarCode;

sub t{
}

1
