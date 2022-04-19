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

Chj::xperlfunc::t -- tests for Chj::xperlfunc

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::xperlfunc::t;
use strict;
use utf8;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental 'signatures';

use Chj::xperlfunc;
use Chj::TEST;

sub wday($tm) {
    [qw(Mon Tue Wed Thu Fri Sat Sun)]->[$tm->wDay]
}

sub f($tm) {
    sprintf '%s %i.%i.%i %s', wday($tm), $tm->mday, $tm->Mon, $tm->Year,
        $tm->Year_and_iso_week_number
}

sub t($t) {
    local $ENV{TZ} = "Europe/Zurich";
    [map { f(xlocaltime($t + $_ * 3600 * 24)) } (0 .. 15)]
}

TEST { t 1640476800 }
[
    'Sun 26.12.2021 2021-W51',
    'Mon 27.12.2021 2021-W52',
    'Tue 28.12.2021 2021-W52',
    'Wed 29.12.2021 2021-W52',
    'Thu 30.12.2021 2021-W52',
    'Fri 31.12.2021 2021-W52',
    'Sat 1.1.2022 2022-WLASTYEAR',
    'Sun 2.1.2022 2022-WLASTYEAR',
    'Mon 3.1.2022 2022-W1',
    'Tue 4.1.2022 2022-W1',
    'Wed 5.1.2022 2022-W1',
    'Thu 6.1.2022 2022-W1',
    'Fri 7.1.2022 2022-W1',
    'Sat 8.1.2022 2022-W1',
    'Sun 9.1.2022 2022-W1',
    'Mon 10.1.2022 2022-W2'
];

TEST { t 1671926400 }
[
    'Sun 25.12.2022 2022-W51',
    'Mon 26.12.2022 2022-W52',
    'Tue 27.12.2022 2022-W52',
    'Wed 28.12.2022 2022-W52',
    'Thu 29.12.2022 2022-W52',
    'Fri 30.12.2022 2022-W52',
    'Sat 31.12.2022 2022-W52',
    'Sun 1.1.2023 2023-WLASTYEAR',
    'Mon 2.1.2023 2023-W1',
    'Tue 3.1.2023 2023-W1',
    'Wed 4.1.2023 2023-W1',
    'Thu 5.1.2023 2023-W1',
    'Fri 6.1.2023 2023-W1',
    'Sat 7.1.2023 2023-W1',
    'Sun 8.1.2023 2023-W1',
    'Mon 9.1.2023 2023-W2'
];

TEST { t 1703376000 }
[
    'Sun 24.12.2023 2023-W51',
    'Mon 25.12.2023 2023-W52',
    'Tue 26.12.2023 2023-W52',
    'Wed 27.12.2023 2023-W52',
    'Thu 28.12.2023 2023-W52',
    'Fri 29.12.2023 2023-W52',
    'Sat 30.12.2023 2023-W52',
    'Sun 31.12.2023 2023-W52',
    'Mon 1.1.2024 2024-W1',
    'Tue 2.1.2024 2024-W1',
    'Wed 3.1.2024 2024-W1',
    'Thu 4.1.2024 2024-W1',
    'Fri 5.1.2024 2024-W1',
    'Sat 6.1.2024 2024-W1',
    'Sun 7.1.2024 2024-W1',
    'Mon 8.1.2024 2024-W2'
];

TEST { t 1734825600 }
[
    'Sun 22.12.2024 2024-W51',     'Mon 23.12.2024 2024-W52',
    'Tue 24.12.2024 2024-W52',     'Wed 25.12.2024 2024-W52',
    'Thu 26.12.2024 2024-W52',     'Fri 27.12.2024 2024-W52',
    'Sat 28.12.2024 2024-W52',     'Sun 29.12.2024 2024-W52',
    'Mon 30.12.2024 2024-W53',     'Tue 31.12.2024 2024-W53',
    'Wed 1.1.2025 2025-WLASTYEAR', 'Thu 2.1.2025 2025-WLASTYEAR',
    'Fri 3.1.2025 2025-WLASTYEAR', 'Sat 4.1.2025 2025-WLASTYEAR',
    'Sun 5.1.2025 2025-WLASTYEAR', 'Mon 6.1.2025 2025-W2'

        #WRONG
];

TEST { t 1766707200 }
[
    'Fri 26.12.2025 2025-W52',     'Sat 27.12.2025 2025-W52',
    'Sun 28.12.2025 2025-W52',     'Mon 29.12.2025 2025-W53',
    'Tue 30.12.2025 2025-W53',     'Wed 31.12.2025 2025-W53',
    'Thu 1.1.2026 2026-WLASTYEAR', 'Fri 2.1.2026 2026-WLASTYEAR',
    'Sat 3.1.2026 2026-WLASTYEAR', 'Sun 4.1.2026 2026-WLASTYEAR',
    'Mon 5.1.2026 2026-W2', 'Tue 6.1.2026 2026-W2', 'Wed 7.1.2026 2026-W2',
    'Thu 8.1.2026 2026-W2', 'Fri 9.1.2026 2026-W2', 'Sat 10.1.2026 2026-W2'

        #WRONG
];

1
