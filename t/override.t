#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Time::StasisField;
use Test::More (tests => 5);

for (
	['Time::StasisField::alarm', sub { alarm(0) } ],
	['Time::StasisField::gmtime', sub { gmtime(0) }],
	['Time::StasisField::localtime', sub {localtime(0) }],
	['Time::StasisField::sleep', sub { sleep(0) }],
	['Time::StasisField::time', sub { time }],
) {
	my ($function, $test) = @$_;
	no strict 'refs';
	no warnings 'redefine';
	my $is_triggered = 0;
	my $original = \&$function;
	local *{$function} = sub { $is_triggered = 1; goto &$original };
	$test->();
	is $is_triggered, 1, "$function is properly installed"
}

