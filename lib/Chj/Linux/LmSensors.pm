#
# Copyright (c) 2016 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Linux::LmSensors

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::Linux::LmSensors;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(sensors_get
              Selector
              Value
              ValueNA
              ValueGroup
              Measurement
            );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use utf8;
use Chj::TEST;


{
    package Chj::Linux::LmSensors::Selector;
    use FP::Predicates qw(is_string);

    use FP::Struct [
                    [*is_string, 'groupname'],
                    [*is_string, 'sensorname'],
                   ], 'FP::Struct::Show';
    _END_
}



{
    package Chj::Linux::LmSensors::ValueBase;
    use FP::Struct [
                    'name', # string
                   ], 'FP::Struct::Show';
    _END_
}

{
    package Chj::Linux::LmSensors::Value;
    use FP::Struct [
                    'value', # bare number
                    'unit', # °C etc.
                    'high_crit', # maybe string
                   ],
                     'Chj::Linux::LmSensors::ValueBase',
                       'FP::Struct::Show';

    sub maybe_value {
        shift->value
    }

    sub value_or {
        shift->value
    }

    _END_
}

{
    package Chj::Linux::LmSensors::ValueNA;
    use FP::Struct [
                   ],
                     'Chj::Linux::LmSensors::ValueBase',
                       'FP::Struct::Show';

    sub maybe_value {
        undef
    }

    sub value_or {
        $_[1]
    }

    _END_
}

{
    package Chj::Linux::LmSensors::ValueGroup;

    use FP::Struct [
                    'name', # string
                    'values', # list of ::Value
                   ], 'FP::Struct::Show';
    _END_
}

{
    package Chj::Linux::LmSensors::Measurement;

    sub by {
        my ($method,$str)=@_;
        sub {
            my ($v)=@_;
            $v->$method eq $str
        }
    };

    use FP::Struct [
                    'time', # unixtime value, ok?
                    'groups', # list of ::ValueGroup
                   ], 'FP::Struct::Show';

    # "expecting 1 element, got 0" meaning the field doesn't exist.
    sub select {
        my ($self, $selector)=@_;
        $self->groups->filter(by "name", $selector->groupname)->xone
          ->values->filter(by "name", $selector->sensorname)->xone
    }

    _END_
}

import Chj::Linux::LmSensors::Selector::constructors;
import Chj::Linux::LmSensors::Value::constructors;
import Chj::Linux::LmSensors::ValueNA::constructors;
import Chj::Linux::LmSensors::ValueGroup::constructors;
import Chj::Linux::LmSensors::Measurement::constructors;


sub parse_value {
    my ($s)=@_;
    chomp $s;
    my ($name,$rest1)=
      $s=~ m{^([\w -]+):[ \t]*(.*)\z}sx
        or die "no name match: '$s'";

    chomp $rest1;

    if ($rest1=~ m{^N/A\s*\z}sx) {
        ValueNA($name)
    } else {
        my ($value,$unit,$rest)=
          $rest1=~ m{^([+-]?\d+(?:\.\d*)?)\s*([°A-Za-z]\w*)\s*(.*)\z}sx
            # wow ewil, space in ' *' would be dropped due to /x of course
            or die "no values match: '$rest1'";
        Value($name,$value,$unit,$rest)
    }
}


TEST {
    parse_value 'fan1:        3770 RPM
'}
  Value('fan1', '3770', 'RPM', '');



use FP::PureArray qw(purearray array_to_purearray);

sub parse_measurement {
    my ($str,$time)=@_;
    my @groups= map {
        my $s=$_;
        my ($groupname, $groupvalues)=
          $s=~ m{^([\w -]+)\n
                    (.*)
                    \z}sx
                      or die "no group match: '$s'";

        my @values= map {
            parse_value $_
        }
          split /\n/, $groupvalues;

        ValueGroup($groupname, array_to_purearray \@values)
    }
      split /\n\n/, $str;

    Measurement($time, array_to_purearray \@groups)
}


use Chj::IO::Command;

sub sensors_get_string {
    my $p= Chj::IO::Command->new_sender({LANG=> "C"},
                                        "sensors", "-A");
    $p->set_encoding("utf-8");
    my $str= $p->xcontent;
    $p->xxfinish;
    $str
}

sub sensors_get {
    parse_measurement(sensors_get_string, time)
}




my $s= 'acpitz-virtual-0
temp1:        +40.0°C  (crit = +127.0°C)
temp2:        +38.0°C  (crit = +104.0°C)

coretemp-isa-0000
Core 0:       +35.0°C  (high = +105.0°C, crit = +105.0°C)
Core 1:       +37.0°C  (high = +105.0°C, crit = +105.0°C)

thinkpad-isa-0000
fan1:        3770 RPM
temp1:        +40.0°C  
temp2:        +53.0°C  
temp3:            N/A  
temp4:        +44.0°C  
temp5:        +33.0°C  
temp6:            N/A  
temp7:        +32.0°C  
temp8:            N/A  
temp9:        +49.0°C  
temp10:       +39.0°C  
temp11:           N/A  
temp12:           N/A  
temp13:           N/A  
temp14:           N/A  
temp15:           N/A  
temp16:           N/A  

';

my $m;
TEST {
    $m= parse_measurement($s, 1234567)
}
  Measurement(1234567,
              purearray
              (ValueGroup('acpitz-virtual-0',
                          purearray
                          (Value('temp1', '+40.0', '°C',
                                 '(crit = +127.0°C)'),
                           Value('temp2', '+38.0', '°C',
                                 '(crit = +104.0°C)'))),
               ValueGroup('coretemp-isa-0000',
                          purearray
                          (Value('Core 0', '+35.0', '°C',
                                 '(high = +105.0°C, crit = +105.0°C)'),
                           Value('Core 1', '+37.0', '°C',
                                 '(high = +105.0°C, crit = +105.0°C)'))),
               ValueGroup('thinkpad-isa-0000',
                          purearray
                          (Value('fan1', '3770', 'RPM', ''),
                           Value('temp1', '+40.0', '°C', ''),
                           Value('temp2', '+53.0', '°C', ''),
                           ValueNA('temp3'),
                           Value('temp4', '+44.0', '°C', ''),
                           Value('temp5', '+33.0', '°C', ''),
                           ValueNA('temp6'),
                           Value('temp7', '+32.0', '°C', ''),
                           ValueNA('temp8'),
                           Value('temp9', '+49.0', '°C', ''),
                           Value('temp10', '+39.0', '°C', ''),
                           ValueNA('temp11'),
                           ValueNA('temp12'),
                           ValueNA('temp13'),
                           ValueNA('temp14'),
                           ValueNA('temp15'),
                           ValueNA('temp16')))));

TEST {
    purearray(Selector ('coretemp-isa-0000', 'Core 1'),
              Selector ('thinkpad-isa-0000', 'temp14'))
      ->map(sub {
                my ($sel)=@_;
                $m->select($sel)->value_or("no val")
            })
  }
  purearray('+37.0', "no val");


1
