#
# Copyright (c) 2022 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#
#

=head1 NAME

FP::Iptables::Rules

=head1 SYNOPSIS

=head1 DESCRIPTION

Very much unfinished, just a subset of iptables functionality is
implemented yet.

=head1 SEE ALSO

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FP::Iptables::Rules;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';
use Exporter "import";

use Chj::TEST;
use FP::List;

# Excluding: Base ACondition AnAction
our @EXPORT=qw(
    Rule Protocol Match Multiport Return Call Actions Rules
    Rule_ Protocol_ Match_ Multiport_ Return_ Call_ Actions_ Rules_
    );
our @EXPORT_OK=qw();
our %EXPORT_TAGS=(default => \@EXPORT, all=>[@EXPORT,@EXPORT_OK]);


package FP::Iptables::Rules::Base {
    use FP::Struct []
        => qw(FP::Struct::Equal FP::Struct::Show);
    _END_ "FP::Iptables::Rules";
}

# ---- rules -----------------------------------------------------------

my $perhaps_xml= sub($maybe_v) {
    defined ($maybe_v) ? $maybe_v->xml : ()
};

package FP::Iptables::Rules::Rule {
    use FP::Ops qw(the_method);
    use FP::List qw(list_of nonempty_list_of);
    use FP::Predicates qw(instance_of maybe);
    use PXML::Tags qw(rule conditions actions);

    use FP::Struct [
        [ list_of(instance_of("FP::Iptables::Rules::ACondition")),
          "conditions" ],
        [ maybe(instance_of("FP::Iptables::Rules::AnAction")),
          # The XML element is called "actions" just because it could
          # be 0 or 1, right?
          "maybe_action" ],
        ]
        => qw(FP::Iptables::Rules::Base);

    sub xml($self) {
        RULE(
            CONDITIONS(
                $self->conditions->map(the_method("xml"))
            ),
            ACTIONS(
                $perhaps_xml->($self->maybe_action)
            ),
            )
    }
    _END_ "FP::Iptables::Rules";
}

package FP::Iptables::Rules::ACondition {
    use FP::Struct []
        => qw(FP::Iptables::Rules::Base);
    _END_
}

package FP::Iptables::Rules::Protocol {
    use PXML::Tags qw(p);
    sub is_protocol_string($v) {
        $v eq "tcp" or $v eq "udp"  # XX and?..
    }
    use FP::Struct [
        [ \&is_protocol_string, "protocol_string" ]
        ]
        => qw(FP::Iptables::Rules::Base);
    sub xml($self) {
        P($self->protocol_string)
    }
    _END_ "FP::Iptables::Rules";
}

package FP::Iptables::Rules::Match {
    use FP::Predicates qw(instance_of);
    use PXML::Tags qw(match);

    use FP::Struct [
        [ instance_of("FP::Iptables::Rules::Protocol"),
          "specifier" ] # ?
        ]
        => qw(FP::Iptables::Rules::ACondition);
    sub xml ($self) {
        MATCH($self->specifier->xml)
    }
    _END_ "FP::Iptables::Rules";
}

package FP::Iptables::Rules::Multiport {
    use FP::List qw(list_of nonempty_list_of);
    use FP::Predicates qw(is_natural0 is_natural maybe);
    use PXML::Tags qw(multiport sports dports);

    sub is_port($v) {
        # XX would port 0 be valid?
        not ref($v) and is_natural($v) and $v <= 65535
    }

    sub perhaps_tag($tagger, $maybe_v) {
        defined($maybe_v) ? $tagger->($maybe_v) : ()
    }

    use FP::Struct [
        [ maybe(nonempty_list_of(\&is_port)), "maybe_sports" ],
        [ maybe(nonempty_list_of(\&is_port)), "maybe_dports" ],
        ]
        => qw(FP::Iptables::Rules::ACondition);
    sub xml($self) {
        # XX bad, declare for check at creation time, please....!
        $self->maybe_sports // $self->maybe_dports
            // die "Multiport requires at least one of sports or dports";
        MULTIPORT(
            perhaps_tag(\&SPORTS, $self->maybe_sports),
            perhaps_tag(\&DPORTS, $self->maybe_dports)
            )
    }
    _END_ "FP::Iptables::Rules";
}


# package FP::Iptables::Rules:: {
#     use PXML::Tags qw();
#     use FP::Struct []
#         => qw(FP::Iptables::Rules::Base);
#     _END_ "FP::Iptables::Rules";
# }

# package FP::Iptables::Rules:: {
#     use PXML::Tags qw();
#     use FP::Struct []
#         => qw(FP::Iptables::Rules::Base);
#     _END_ "FP::Iptables::Rules";
# }


# ----

package FP::Iptables::Rules::AnAction {
    # and I don't mean Rust "Some", but "Interface"--ok use "An"
    use FP::Struct []
        => qw(FP::Iptables::Rules::Base);
    _END_
}

package FP::Iptables::Rules::Return {
    use FP::Ops qw(the_method);
    use PXML::Tags qw(RETURN);
    use FP::Struct []
        => qw(FP::Iptables::Rules::AnAction);
    sub xml($self) {
        RETURN()
    }
    _END_ "FP::Iptables::Rules";
}

package FP::Iptables::Rules::Call {
    use FP::Ops qw(the_method);
    use FP::Predicates qw(is_string);
    use PXML::Tags qw(call);

    use FP::Struct [
        [ \&is_string, "chain_name" ]
        ]
        => qw(FP::Iptables::Rules::AnAction);
    sub xml($self) {
        CALL(PXML::Element->new($self->chain_name, {}, []))
    }
    _END_ "FP::Iptables::Rules";
}

package FP::Iptables::Rules::Actions {
    use FP::Ops qw(the_method);
    use FP::List qw(list_of nonempty_list_of);
    use FP::Predicates qw(instance_of);
    use PXML::Tags qw(actions);

    use FP::Struct [
        [ list_of(instance_of("FP::Iptables::Rules::AnAction")),
          "items" ],
        ]
        => qw(FP::Iptables::Rules::Base);
    sub xml($self) {
        ACTIONS($self->actions->map(the_method("xml")))
    }
    _END_ "FP::Iptables::Rules";
}


# Chain

# Table


# ---- main -----------------------------------------------------------

package FP::Iptables::Rules::Rules {
    use FP::Ops qw(the_method);
    use FP::List qw(list_of nonempty_list_of);
    use FP::Predicates qw(instance_of);
    use PXML::Tags qw(iptables-rules);

    use FP::Struct [
        [ list_of(instance_of("FP::Iptables::Rules::Table")),
          "tables" ]
        ]
        => qw(FP::Iptables::Rules::Base);
    sub xml ($self) {
        IPTABLES_RULES($self->tables->map(the_method("xml")))
    }
    _END_ "FP::Iptables::Rules";
}



TEST {
    Rule(
        list(Match(Protocol("tcp")),
             Multiport(undef, list(22))),
        Call("f2b-sshd"))
        ->xml->string
}
'<rule><conditions><match><p>tcp</p></match><multiport><dports>22</dports></multiport></conditions><actions><call><f2b-sshd/></call></actions></rule>';

TEST {
    Rule(
        list(Match(Protocol("tcp")),
             Multiport(undef, list(22))),
        Return())
        ->xml->string
}
'<rule><conditions><match><p>tcp</p></match><multiport><dports>22</dports></multiport></conditions><actions><RETURN/></actions></rule>';


1
