#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Time::StasisField (qw{:all});
use Test::More(tests => 200);

my $class = 'Time::StasisField';

sub test_alarm {
	#alarms are triggered after n seconds
	#triggered by:
	#time
	#tick
	#now(@_)
	#alarm returns time of previous alarm
	#alarm(0) unsets the alarm
}

sub test_frozen_time {
	my $now = $class->now;

	$class->freeze;
	is time, $now, 'time does not move while frozen';
	cmp_ok $class->tick, '>', $now, 'freezing time does not freeze tick';
	is $class->now(12345), 12345, 'freezing time does not affect setting now';
	sleep(2);
	is $class->now, 12347, 'freezing time does not affect sleep';
	$class->unfreeze;
	is time, 12348, 'time continues once unfrozen';
}

sub test_normal_time {
	cmp_ok time - CORE::time, '<=', 1, 'time starts with the same value as CORE::time';
	is time, $class->now, 'the time is now';
	is time + 1, time, 'time marches on';
	my $now = $class->now;
	time for 1 .. 10;
	is $class->now, $now + 10, 'time is predictable';
}

sub test_now {
	is $class->now, $class->now, 'now is now';
	is $class->now(12345), 12345, 'now is modifiable';
	is $class->now(12345.5), 12345, 'now returns integer time';
	is $class->now(-12345), -12345, 'now can be negative';
	is $class->now($class->now(42.25)), $class->now(42.25), 'now is idempotent';
	ok ! (eval { $class->now('bad') ;1 }), 'now only accepts numbers';
}

sub test_seconds_per_tick {
	my ($now, $tick_size);

	is $class->seconds_per_tick, 1, 'seconds_per_tick returns the tick size';

	for (
		[-3 => 'negative seconds'],
		[-0.25 => 'negative subseconds'],
		[0 => 'zero seconds'],
		[0.25 => 'positive subseconds'],
		[5 => 'positive seconds'],
	) {
		my ($tick_size, $label) = @$_;
		is $class->seconds_per_tick($tick_size), $tick_size, "seconds_per_tick supports $label";
		my $now = $class->now;
		is time, int($now + $tick_size), "time returns an integer when seconds_per_tick is set to $label";
		time for (1 .. 3);
		is $class->now, int($now + 4 * $tick_size), "seconds_per_tick moves time by the proper number of seconds given $label";
	}

	$class->seconds_per_tick(1);
}

sub test_sleep {
	for (
		[0 => 'zero seconds'],
		[0.25 => 'positive subseconds'],
		[5 => 'positive seconds'],
	) {
		my ($duration, $label) = @$_;
		my $now = $class->now;
		is sleep($duration), int($duration), "sleep returns the integer number of seconds passed given $label";
		is $class->now, int($now + $duration), "sleep advances time by the proper number of seconds given $label";
	}

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		CORE::alarm(1);
		sleep(-2);
		is $is_triggered, 1, 'sleep pauses runtime indefinitely given a negative duration';
	};

	do {
		my $is_triggered = 0;
		local $SIG{ALRM} = sub { $is_triggered = 1};
		CORE::alarm(1);
		sleep;
		is $is_triggered, 1, 'sleep pauses runtime indefinitely when called without arguments';
	};

}

sub test_stasis_field_boundaries {
}

sub test_tick {
	my $now;
	is $class->tick, $class->now, 'tick returns now';
	$now = $class->now;
	cmp_ok $class->tick, '>', $now, 'tick advances time';
	$class->seconds_per_tick(5);
	$now = $class->now;
	is $class->tick, $now + 5, 'tick obeys seconds_per_tick';
	$class->seconds_per_tick(1);

	my $is_triggered = 0;
	local $SIG{ALRM} = sub { $is_triggered = 1};
	alarm(1);
	$class->tick;
	is $is_triggered, 1, 'tick triggers a set alarm';
}

for my $test (sort grep { $_ =~ /^test_/ } keys %{main::}) {
	do {
		local $\ = "\n";
		local $, = " ";
		print '#', split /_/, $test;
	};
	$class->engage;
	do { no strict 'refs'; &$test };
	$class->disengage;
}

#my $now;
#
#
#is $class->now, $class->now, 'now without arguments is not a mutating call';
#$now = $class->now;
#is $class->now($now + 0.5), $now, 'now always returns integer seconds';
#
#is time, $class->now, 'time returns now';
#$now = $class->now;
#is time, $now + 1, 'time advances now';
#is time + 1, time, 'time advances in a controllable manner';
#
#is $class->advance(3), $class->now, 'advance returns now';
#$now = $class->now;
#is $class->advance(3), $now + 3, 'advance moves time by N seconds';
#is $class->advance(-3), $now, 'advance can move time backwards as well';
#$class->advance(0.5);
#is $class->advance(0.5), $now + 1, 'advance works with partial seconds';
#
#$class->seconds_per_tick(5);
#$now = $class->now;
#is $class->seconds_per_tick, 5, 'seconds_per_tick returns the current tick size';
#is time, $now + 5, 'seconds_per_tick modifies the amount with which time changes';
#$class->seconds_per_tick(0.5);
#time;
#is time, $now + 6, 'seconds_per_tick works with partial seconds as well';
#$class->seconds_per_tick(1);
#
#$class->freeze;
#$now = $class->now;
#time for 0 .. 10;
#is $class->now, $now, 'time does not change when frozen';
#is $class->advance(1), $now + 1, 'freezing time does not stop direct calls to advance';
#$class->unfreeze;
#is time, $now + 2, 'time continues once unfrozen';
#
#
