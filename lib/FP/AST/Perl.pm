#
# Copyright (c) 2019-2020 Christian Jaeger, copying@christianjaeger.ch
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
    use FP::List; use FP::Equal ":all"; use FP::Ops qw(regex_substitute);

    is Get(ScalarVar "foo")->string, '$foo';
    is Get(ArrayVar "foo")->string, '@foo';
    is Get(HashVar "foo::bar")->string, '%foo::bar';
    is Ref(HashVar "foo::bar")->string, '\%foo::bar';

    my $codefoo = CodeVar("foo");
    my $arrayfoo = ArrayVar("foo");
    my $lexfoo = ScalarVar("foo");
    is App(Get($codefoo), list())->string,
       '&foo()';
    is AppP(Get($codefoo), list())->string,
       'foo()';
    is AppP(Get($lexfoo), list(Ref($codefoo)))->string,
       '$foo->(\&foo)';
    is eval { App(Get(HashVar "foo"), list())->string } ||
            regex_substitute(sub{s/ at .*//s}, $@),
       'HASH var can\'t be called';
    is AppP(Get($lexfoo), list(Get($lexfoo), Get($arrayfoo), Ref($arrayfoo)))->string,
       '$foo->($foo, @foo, \@foo)';
    is AppP(Get($codefoo), list(Get(ScalarVar 'foo'), Literal(Number 123)))->string,
       'foo($foo, 123)';
    is AppP(Get($codefoo), list(Get($lexfoo), Literal(String 123)))->string,
       'foo($foo, \'123\')';

    # Semicolons are like a compile time (AST level) operator:
    is Semicolon(Get(ScalarVar "a"), Get(ScalarVar "b"))->string, '$a; $b';
    # to end with a semicolon you could use:
    is Semicolon(Get(ScalarVar "a"), Noop)->string, '$a; ';

    # The n-ary `semicolons` function builds a Semicolon chain for
    # you (right-associated):
    is_equal semicolons(), Noop;
    is_equal semicolons("x"), "x";
        # ^ no `Semicolon` instantiation thus no type failure because
        #   of the string
    my $sems = semicolons(map {Get ScalarVar $_} qw(a b c));
    is_equal $sems,
             Semicolon(Get(ScalarVar('a')),
                       Semicolon(Get(ScalarVar('b')),
                                 Get(ScalarVar('c'))));
    is $sems->string, '$a; $b; $c';

    is commas(map {Get ScalarVar $_} qw(a b c))->string,
       '$a, $b, $c';

    is Let(list(ScalarVar("foo"), ScalarVar("bar")),
           Get(ArrayVar "baz"),
           semicolons(
               AppP(Get(CodeVar "print"),
                        list Literal String "Hello"),
               Get(ScalarVar("bar"))))->string,
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
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";
use Exporter "import";

our @EXPORT = qw();
my @classes = qw(
    ScalarVar CodeVar HashVar ArrayVar Glob
    App AppP Get Ref
    Number String
    Literal
    Semicolon Comma Noop Let);
our @EXPORT_OK = (
    @classes, qw(
        is_packvar_type
        is_var
        is_expr is_nonnoop_expr is_noop
        semicolons commas)
);

our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::Predicates ":all";

#use Chj::TEST;
use FP::List;
use FP::Combinators2 qw(right_associate_);

# import the constructors of the classes defined below
for my $name (@classes) {
    "FP::AST::Perl::${name}::constructors"->import()
}

package FP::AST::_::Perl {
    use FP::Docstring;

    use FP::Struct [] => "FP::Abstract::Pure",
        "FP::Struct::Equal", "FP::Struct::Show";

    sub string_proto($self) {
        __ "stringification when used as the callee in AppP";
        $self->string
    }

    _END_
}

# Variables

package FP::AST::Perl::Var {
    use FP::Predicates ":all";

    use FP::Struct [
        [*is_string, 'name'],

        # ^ XX is_package_name ? But isn't everything allowed? But
        # then todo proper printing.
        #FUTURE: [*is_bool, 'is_lexical'] ?
    ] => "FP::AST::_::Perl";

    sub string($self) {
        $self->sigil . $self->name
    }
    sub callderef($self) { die $self->type_name . " var can't be called" }

    _END_
}

*is_var = instance_of
    "FP::AST::Perl::Var";    ## XX Are those not all auto generated MAN ???

# XX move to FP::Predicates? Or FP::Parser::Perl ?
sub is_lexvar_string ($) {
    my ($str) = @_;
    $str =~ /^\w+\z/
}

package FP::AST::Perl::ScalarVar {
    use FP::Struct [] => "FP::AST::Perl::Var";
    sub type_name($self) {"SCALAR"}
    sub sigil($self)     {'$'}
    sub callderef($self) {'->'}
    _END_
}

package FP::AST::Perl::CodeVar {
    use FP::Struct [] => "FP::AST::Perl::Var";
    sub type_name($self) {"CODE"}
    sub sigil($self)     {'&'}
    sub callderef($self) {''}

    sub string_proto($self) { $self->name }
    _END_
}

package FP::AST::Perl::HashVar {
    use FP::Struct [] => "FP::AST::Perl::Var";
    sub type_name($self) {"HASH"}
    sub sigil($self)     {'%'}
    _END_
}

package FP::AST::Perl::ArrayVar {
    use FP::Struct [] => "FP::AST::Perl::Var";
    sub type_name($self) {"ARRAY"}
    sub sigil($self)     {'@'}
    _END_
}

package FP::AST::Perl::Glob {
    use FP::Struct [] => "FP::AST::Perl::Var";    # XX *?*
    sub type_name($self) {"GLOB"}
    sub sigil($self)     {'*'}
    _END_
}

# Expressions

package FP::AST::Perl::Expr {

    use FP::Struct [] => "FP::AST::_::Perl";

    _END_
}

*is_expr         = instance_of "FP::AST::Perl::Expr";
*is_nonnoop_expr = both * is_expr, complement * is_noop;

# Do we need to distinguish context (list vs. scalar [vs. void]),
# really? No, since the *dynamic* context determines this!

package FP::AST::Perl::Get {
    use FP::Predicates ":all";

    use FP::Struct [[*FP::AST::Perl::is_var, 'var'],] => "FP::AST::Perl::Expr";

    # XX problem is, for CODE vars, Get is only valid in App proc
    # context! Otherwise, Ref must be used! How to type check?
    # Different methods than just string I guess!!

    # XX BTW eliminate those delegates? Just call manually? OR: use
    # Var directly in App proc ??

    sub string($self) {
        $self->var->string
    }

    sub string_proto($self) {
        $self->var->string_proto
    }

    sub callderef($self) {
        $self->var->callderef
    }

    _END_
}

# Take referenceS, 'instead of just Get-ing the valueS':

package FP::AST::Perl::Ref {
    use FP::Predicates ":all";

    use FP::Struct [[*FP::AST::Perl::is_var, 'var'],] => "FP::AST::Perl::Expr";

    sub string($self) {
        "\\" . $self->var->string
    }

    # sub string_proto ($self) {
    #     # $self->var->string_proto
    #     #die "there is no prototype call with a ref expression"
    #         # ok? or just omit and let it fall back to ->string ? but
    #         # i DO think this call should never happen, right?
    # }

    sub callderef($self) {

        # taking a ref means the call will have to deref it, always
        '->'
    }

    _END_
}

# *is_ref = instance_of "FP::AST::Perl::Ref";

package FP::AST::Perl::App {
    use FP::Predicates ":all";
    use FP::List ":all";
    use FP::Ops ":all";

    use FP::Struct [
        [*FP::AST::Perl::is_expr, 'proc'],
        [list_of * FP::AST::Perl::is_expr, 'argexprs'],

        # ^ yes, proc is also an expr, but only yielding one (usable)
        # value, as opposed to argexprs which may yield more used
        # values than there are exprs (at least here; not
        # (necessarily) in AppP).
    ] => "FP::AST::Perl::Expr";

    sub string($self) {
        $self->proc_string
            . $self->proc->callderef . "("
            . $self->argexprs->map(the_method "string")->strings_join(", ")
            .

            # ^ XX are parens needed around arguments?
            ")"
    }

    sub proc_string($self) {
        $self->proc->string
    }
    _END_
}

package FP::AST::Perl::AppP {

    # App with exposure to prototypes
    use FP::Struct [] => "FP::AST::Perl::App";

    sub proc_string($self) {
        $self->proc->string_proto
    }

    _END_
}

# Literals

package FP::AST::Perl::Value {
    use FP::Predicates ":all";

    use FP::Struct [] => "FP::AST::_::Perl";

    # missing string method  XX interface

    _END_
}

*is_value = instance_of "FP::AST::Perl::Value";

package FP::AST::Perl::Number {
    use FP::Predicates ":all";
    use Scalar::Util qw(looks_like_number);

    use FP::Struct [[*looks_like_number, 'perlvalue'],] =>
        "FP::AST::Perl::Value";

    sub string($self) {
        $self->perlvalue    # no quoting
    }

    _END_
}

package FP::AST::Perl::String {
    use FP::Predicates ":all";
    use Chj::singlequote;

    use FP::Struct ['perlvalue',] => "FP::AST::Perl::Value";

    sub string($self) {
        singlequote($self->perlvalue)
    }

    _END_
}

package FP::AST::Perl::Literal {
    use FP::Predicates ":all";
    use FP::List ":all";
    use FP::Ops ":all";

    use FP::Struct [[*FP::AST::Perl::is_value, 'value'],] =>
        "FP::AST::Perl::Expr";

    sub string($self) {
        $self->value->string
    }

    _END_
}

package FP::AST::Perl::Semicolon {
    use FP::Struct [[*FP::AST::Perl::is_expr, 'a'],
        [*FP::AST::Perl::is_expr, 'b'],] => "FP::AST::Perl::Expr";

    sub string($self) {
        $self->a->string . "; " . $self->b->string
    }
    _END_
}

# mostly-copy-paste of above
package FP::AST::Perl::Comma {
    use FP::Struct [[*FP::AST::Perl::is_expr, 'a'],
        [*FP::AST::Perl::is_expr, 'b'],] => "FP::AST::Perl::Expr";

    sub string($self) {
        $self->a->string . ", " . $self->b->string
    }
    _END_
}

package FP::AST::Perl::Noop {
    use FP::Struct [] => "FP::AST::Perl::Expr";

    sub string($self) {
        ""
    }
    _END_
}

*is_noop = instance_of "FP::AST::Perl::Noop";

*semicolons = right_associate_ * Semicolon, Noop();
*commas     = right_associate_ * Comma,     Noop();

package FP::AST::Perl::Let {
    use FP::Predicates;
    use FP::List;
    use FP::Ops ":all";

    use FP::Struct [
        [list_of * FP::AST::Perl::is_var, 'vars'],
        [*FP::AST::Perl::is_nonnoop_expr, 'expr'],
        [*FP::AST::Perl::is_expr,         'body'],
    ] => "FP::AST::Perl::Expr";

    sub string($self) {
        my $vars     = $self->vars;
        my $multiple = $vars->length > 1;
        "my "
            . ($multiple ? "(" : "")
            . $vars->map(the_method "string")->strings_join(", ")
            . ($multiple ? ")" : "") . " = "
            . $self->expr->string
            . "; "    # XX like Semicolon! But not the same *?* Q
            . $self->body->string
    }
    _END_
}

sub String;
sub Literal;

sub t {
}

1
