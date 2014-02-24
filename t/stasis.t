#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Time::StasisField (qw{:all});
use Test::More(tests => 200);

Time::StasisField::engage;

cmp_ok time - CORE::time, '<=', 1, '';
is now, now, '';
is now + 1, time, '';
is time + 1, time, '';

is now + 3, advance_time(3), '';
is advance_time(3), now, '';

set_seconds_per_tick(5);
is now() + 5, time, '';

