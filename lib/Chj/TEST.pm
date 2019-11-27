#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::TEST

=head1 SYNOPSIS

    use Chj::TEST;
    # or
    use Chj::TEST use=> 'Method::Signatures'
        #, use=> ['Foo::Bar', qw(bar baz)],
        #, require=> 'CGI'
        ;
    # ^ this will use or require the indicated modules, and if RUN_TESTS
    # is set and they fail, will gracefully fail with a SKIP testing message
    # (if RUN_TESTS is not set, it will die as normally).

    TEST { 1+1 } 2; # success
    TEST { 1+1 } "2"; # fails,
        # because equality is compared on the result of Data::Dumper

    # compute also result lazily:
    TEST { 1+1 } GIVES {3-1}; # success

    TEST_STDOUT { print "Hello" } "Hello";
    TEST_EXCEPTION { die "Hello" } "Hello"; # " at .. line .." and
                                            # backtrace are cut off


    use Chj::TEST ':all';

    my $result= run_tests(__PACKAGE__);
    is $result->fail, 0; # 0 failures
    is $result->success > 0, 1;

    #run_tests;
    #  or
    #run_tests __PACKAGE__, "Another::Package";
    #  or
    #run_tests_ packages=> __PACKAGE__, numbers=>[2..4];
    #   aliases package, number, no also accepted

    #  For conditional running the tests as part of a global test suite:
    #perhaps_run_tests "main" or do_something_else;
    #  This will run run_tests("main") iff the RUN_TESTS environment
    #  variable is true, otherwise run do_something_else.

=head1 DESCRIPTION

If the `TEST` environmental variable is set to false (as opposed to
not set at all), tests are dropped. This saves the memory otherwise
required to hold the test code and results.

=head1 SEE ALSO

L<Chj::noTEST>

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package Chj::TEST;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TEST TEST_STDOUT TEST_EXCEPTION GIVES perhaps_run_tests);
@EXPORT_OK=qw(run_tests run_tests_ no_tests);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Carp;
use Chj::singlequote;

# get the style
sub run_tests_style { # "old" or "tap"
    if (my $rt= $ENV{RUN_TESTS}) {
        ($rt=~ /(old|pod_snippets)/i ? "old" :
         #$rt=~ /(new|tap)/i ? "tap" :
         "tap")
    } else {
        # Use from the repl can't run "tap" style as that one will
        # fail on re-runs
        "old"
    }
}

our $run_tests_style; # used internally only, see sub run_tests_style
                      # ($ENV{RUN_TESTS}) how to set it. OK?

sub style_switch {
    my $choices= shift;
    my $handler= $choices->{$run_tests_style}
      or die "missing choice for style '$run_tests_style'";
    goto $handler
}



# remove 'use' and 'require' arguments from import list, run them,
# then delegate to Exporter

sub import {
    my $class=shift;
    my ($package, $filename, $line)= caller;
    my @args;
    for (my $i=0; $i < @_; $i++) {
        my $v= $_[$i];
        if ($v eq "use" or $v eq "require") {
            my $val= $_[$i+1];
            defined $val
              or croak "undef given as 'require' parameter";
            my ($module,@args)= do {
                if (ref($val) eq "ARRAY") {
                    @$val
                } elsif (length $val) {
                    ($val)
                } else {
                    croak "value given as 'require' parameter must be a string or array";
                }
            };
            my $smallcode=
              ("$v $module "
               .join(",", map {singlequote $_} @args));
            $filename=~ /[\r\n]/
              and die "possible security issue"; # XXX: how to do it fully right?
            my $code= "#line $line $filename\npackage $package; $smallcode; 1";
            if (eval $code) {
                # ok
            } else {
                if (my $rt= $ENV{RUN_TESTS}) {
                    if ($rt=~ /pod_snippets/i) {
                        die "TEST use<$module> failed: $smallcode";
                    } else {
                        #carp "RUN_TESTS is set and we failed to $smallcode";
                        require Test::More;
                        Test::More::plan (skip_all=> "failed to $smallcode");
                        exit 1; # necessary?
                    }
                } else {
                    die $@
                }
            }
            $i++;
        } else {
            push @args, $v
        }
    }
    my $sub= $class->can("SUPER::import")
      or die "$class does not have an 'import' procedure";
    @_=($class, @args); goto &$sub;
}



use Chj::xIO 'capture_stdout_';

our $tests_by_package={};
our $num_by_package={};

our $dropped_tests=0;

sub no_tests () {
    exists $ENV{TEST} and !$ENV{TEST}
}

sub _TEST {
    my ($proc,$res)=@_;
    if (no_tests) {
        $dropped_tests++;
    } else {
        my ($package, $filename, $line) = caller(1);
        $$num_by_package{$package}++;
        push @{$$tests_by_package{$package}},
          [$proc,$res, $$num_by_package{$package}, ($package, $filename, $line)];
    }
}

sub TEST (&$) {
    _TEST(@_)
}

sub TEST_STDOUT (&$) {
    my ($proc,$res)=@_;
    _TEST(sub{capture_stdout_($proc)}, $res);
}

sub TEST_EXCEPTION (&$) {
    my ($proc,$res)=@_;
    _TEST(sub{
              if (eval {
                  &$proc();
                  1
              }) {
                  undef
              } else {
                  my $msg= "$@";
                  $msg=~ s| at .*? line \d*.*||s;
                  $msg
              }
          },
          $res);
}

sub GIVES (&) {
    my ($thunk)=@_;
    bless $thunk, "Chj::TEST::GIVES";
}


package Chj::TEST::Test::Builder {
    our @ISA= qw(Test::Builder);
    # sub level {
    #      my( $self, $level ) = @_;
    #      # original just sets $Level in Test::Builder to $level if
    #      # defined; returns $Level
    #      18
    # }
    # Ah, ^ that won't ever work since the sub at the right location
    # already returned after value generation.  So, fake it
    # completely instead:
    our $fake_caller;
    sub caller {
        my( $self, $height ) = @_;
        if ($fake_caller) {
            wantarray ? @$fake_caller : $$fake_caller[0]
        } else {
            my $m= $self->can("SUPER::caller")
                or die "bug";
            goto $m
        }
    }
}


use FP::Equal qw(relaxedequal);
use FP::Show;

sub eval_test ($$) {
    my ($t,$stat)=@_;
    my ($proc,$res, $num, $package, $filename, $line)=@$t;
    style_switch +{
        old=> sub {
            print "running test $num..";
        },
        tap=> sub {
            # say nothing, the ok at the end will say it; XXX: capture
            # output! then present that after the "not ok" output.
        },
    };

    my ($got, $maybe_e);
    my $action= sub {
        $got= &$proc;
        if (ref ($res) eq 'Chj::TEST::GIVES') {
            $res= &$res;
        }
    };
    style_switch +{
        old=> $action,
        tap=> sub {
            eval {
                &$action;
                1
            } || do {
                $maybe_e= [$@]; # box it to ensure not undef
            }
        },
    };

    my $location= "at $filename line $line";
    my $nicelocation= "line $line";
    if (! $maybe_e and relaxedequal($got, $res)) {
        style_switch +{
            old=> sub {
                print "ok\n";
            },
            tap=> sub {
                pass($nicelocation);
            },
        };
        $$stat{success}++
    } else {
        my $gotstr= show $got;
        my $resstr= show $res;

        style_switch +{
            old=> sub {
                die "bug, shouldn't happen in this mode"
                    if defined $maybe_e;
                print "FAIL $location:\n";
                print "       got: $gotstr\n";
                print "  expected: $resstr\n";
            },
            tap=> sub {
                # fail($location);
                # want to avoid it reporting this file as the location, thus use this:
                my $tb = Test::More->builder;
                (ref ($tb) eq 'Test::Builder' or
                 ref ($tb) eq 'Chj::TEST::Test::Builder'
                 or die "unexpected class of: $tb");
                bless $tb, 'Chj::TEST::Test::Builder';
                # NOTE: Test::More->builder is a singleton and
                # *remains* blessed!
                local $Chj::TEST::Test::Builder::fake_caller=
                    [$package, $filename, $line];
                #$tb->ok( 0, $nicelocation);
                # On some systems (Test::Builder versions?), the above
                # hackery doesn't work (sigh, move to Test2::*?), thus
                # provide the full location info anyway:
                $tb->ok( 0, $location);

                if (defined $maybe_e) {
                    diag("Exception: $$maybe_e[0]");
                } else {
                    diag("       got: $gotstr\n".
                         "  expected: $resstr\n");
                }
            },
        };
        $$stat{fail}++
    }
}

sub run_tests_for_package {
    my ($package,$stat,$maybe_testnumbers)=@_;

    my $action= sub {
        if (my $tests= $$tests_by_package{$package}) {
            if (defined $maybe_testnumbers) {
                style_switch +{
                    old=> sub {
                        print "=== running selected tests in package '$package'\n";
                    },
                    tap=> sub {
                        # XX better?
                        warn "=== running selected tests in package '$package'\n";
                    },
                };
                for my $number (@$maybe_testnumbers) {
                    if ($number=~ /^\d+\z/ and $number > 0
                        and (my $test= $$tests[$number-1])) {
                        eval_test $test, $stat
                    } else {
                        warn "ignoring invalid test number '$number'";
                    }
                }
            } else {
                my $action= sub {
                    for my $test (@$tests) {
                        eval_test $test, $stat
                    }
                };
                style_switch +{
                    old=> sub {
                        print "=== running tests in package '$package'\n";
                        &$action;
                    },
                    tap=> sub {
                        plan(tests=> scalar @$tests);
                        &$action;
                        done_testing();
                    }
                };
            }
        } else {
            style_switch +{
                old=> sub {
                    print "=== no tests for package '$package'\n";
                },
                tap=> sub {
                    # Can't do 0 tests, planning for it throws an
                    # exception right away, and not planning will fail
                    # in the upper level instead. Thus, fake test result:
                    plan(tests=> 1);
                    pass("no tests for package '$package'");
                    done_testing();
                },
            };
        }
    };

    style_switch +{
        old=> $action,
        tap=> sub {
            subtest("Package $package" => $action);
        },
    };
}

sub unify_values {
    my $maybe_values;
    for (@_) {
        if (ref $_) {
            push @$maybe_values, @$_
        } elsif (defined $_) {
            push @$maybe_values, $_
        }
    }
    $maybe_values
}

package Chj::TEST::Result {
    my $accessor= sub {
        my ($field)= @_;
        sub { my $s=shift; $$s{$field} }
    };
    *fail= $accessor->("fail");
    *success= $accessor->("success");
}

sub run_tests_ {
    @_ % 2 and die "need even number of arguments";
    my $args= +{@_};
    my $maybe_packages=
      unify_values delete $$args{packages}, delete $$args{package};
    my $maybe_testnumbers=
      unify_values delete $$args{numbers}, delete $$args{number},
        delete $$args{no};
    for (sort keys %$args) { warn "run_tests_: unknown argument '$_'" }

    local $run_tests_style //= run_tests_style;

    local $|= 1;

    style_switch +{
        old=> sub {
            print "==== run_tests in $run_tests_style style ====\n";
        },
        tap=> sub {
            # if run_tests is called from perhaps_run_tests this was
            # already done but can't count on that:
            require Test::More;
            import Test::More;
        },
    };

    my $stat= bless {success=>0, fail=>0}, "Chj::TEST::Result";

    my $packages= do {
        if (defined $maybe_packages and @$maybe_packages) {
            $maybe_packages;
        } else {
            [ sort keys %$tests_by_package ]
        }
    };
    my $action= sub {
        run_tests_for_package $_,$stat,$maybe_testnumbers
            for @$packages;
    };

    style_switch +{
        old=> sub {
            &$action;
            print "===\n";
            print "=> $$stat{success} success(es), $$stat{fail} failure(s)\n";
        },
        tap=> sub {
            plan(tests=> scalar @$packages);
            &$action;
            done_testing();
        },
    };

    $stat
}


sub run_tests {
    my $packages= [@_];
    run_tests_ packages=> $packages;
}

# run tests for test suite:

sub perhaps_run_tests {
    my $args= [@_];
    if ($ENV{RUN_TESTS}) {
        # run TEST forms (called as part of test suite)

        die "Tests were dropped due to the TEST environmental "
          ."variable being set to false"
            if $dropped_tests;

        local $run_tests_style //= run_tests_style;

        require Test::More;
        import Test::More;

        style_switch +{
            old=> sub {
                # Outer single TAP wrapper around the running of the
                # whole test suite. # XX could still report individual
                # failures by collecting them up, perhaps even simply
                # via Capture::Tiny. Not currently done.
                is( eval { run_tests(@$args)->fail } // do { diag ($@); undef},
                    0,
                    "run_tests" );
                done_testing();
            },
            tap=> sub {
                # Run each test as a TAP test.
                # Handle exceptions at each individual test, OK?
                run_tests(@$args);
            },
        };

        1  # so that one can write  `perhaps_run_tests or something_else;`
    } else {
        ()
    }
}



1
