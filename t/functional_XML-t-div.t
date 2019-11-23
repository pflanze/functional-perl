#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

use lib "./lib";
use Chj::xperlfunc ":all";

$ENV{RUN_TESTS}=1; xexec_safe "functional_XML/t/div";

# XX run functional_XML/t/stream as well? That one is slow, though.