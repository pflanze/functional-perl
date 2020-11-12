
# general setup for testing.

$ENV{TEST} = 1;    # make sure that Chj::TEST TEST { } snippets are not
                   # dropped because of an accidental setting of the TEST
                   # env var by the user.

1
