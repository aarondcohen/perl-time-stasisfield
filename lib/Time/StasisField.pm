package Time::StasisField;

use strict;
use warnings;

use POSIX (qw{SIGALRM});
use Scalar::Util (qw{set_prototype});

our $VERSION = '0.01';

############################
# Core Overrides
############################

BEGIN {
	for my $function (qw{
		alarm
		gmtime
		localtime
		sleep
		time
	}) {
		no strict 'refs';
		*{"CORE::GLOBAL::$function"} = set_prototype(
			sub { unshift @_, 'Time::StasisField'; goto &{"Time::StasisField::$function"} },
			prototype("CORE::$function")
		);
	}
}

############################
# Private Class Variables
############################

my $alarm_time;
my $current_time = 0;
my $is_alarm_set = 0;
my $is_engaged = 0;
my $is_frozen = 0;
my $seconds_per_tick = 1;

sub is_alarm_set { $is_alarm_set }
sub is_engaged   { $is_engaged }
sub is_frozen    { $is_frozen }

############################
# Helper Functions
############################

sub _validate_number {
	my $class = shift;

	#Make sure the value is numeric
	use warnings (FATAL => 'all');
	no warnings ("void");
	int($_[0]);
}

sub _trigger_alarm {
	my $class = shift;

	return
	  if ! $is_alarm_set
	  || $class->now < $alarm_time;

	CORE::alarm(0);
	$is_alarm_set = 0;
	kill SIGALRM, $$;
}

############################
# API
############################

sub engage {
	my $class = shift;

	if ($is_engaged) {
		#Update now to real time
		$current_time = CORE::time;
		#Trigger the alarm that may have occurred during the transition
		$class->_trigger_alarm;

	} else {
		#Turn off the alarm so that we don't accidentally throw while switching state
		my $old_alarm = $class->alarm(0);

		$is_engaged = 1;
		$current_time = CORE::time;

		#Turn the alarm back on
		$class->alarm($old_alarm || 0);
	}

	return;
}

sub disengage {
	my $class = shift;

	return unless $is_engaged;

	$current_time = CORE::time;
	$is_engaged = 0;

	#Start the system alarm from now
	$class->alarm($alarm_time - $current_time) if $is_alarm_set;
	#Trigger the alarm that may have occurred during the transition
	$class->_trigger_alarm;

	return;
}

sub now {
	my $class = shift;

	return CORE::time unless $is_engaged;

	if (@_) {
		$class->_validate_number($_[0]);
		$current_time = $_[0];
		$class->_trigger_alarm;
	}

	return int($current_time);
}

sub seconds_per_tick {
	my $class = shift;

	if (@_) {
		$class->_validate_number($_[0]);
		$seconds_per_tick = $_[0];
	}

	return $seconds_per_tick;
}

sub tick {
	my $class = shift;

	return CORE::time unless $is_engaged;

	$current_time += $class->seconds_per_tick;
	$class->_trigger_alarm;

	return $class->now;
}

sub freeze   { $is_frozen = 1 }
sub unfreeze { $is_frozen = 0 }

sub alarm {
	my $class = shift;
	my $offset = @_ ? $_[0] : $_;

	return CORE::alarm($offset) unless $is_engaged;

	$class->_validate_number($offset);

	my $previous_alarm_time_remaining =
		! defined $alarm_time ? $alarm_time :
		$is_alarm_set ? $alarm_time - $class->now : 0;
	$alarm_time = $offset > -1 ? $class->now + int($offset) : undef;
	$is_alarm_set = $offset >= 1;

	return $previous_alarm_time_remaining;
}

sub gmtime {
	my $class = shift;

	use warnings (FATAL => 'all');
	CORE::gmtime(@_ ? $_[0] : time);
}

sub localtime {
	my $class = shift;

	use warnings (FATAL => 'all');
	CORE::localtime(@_ ? $_[0] : time);
}

sub sleep {
	my $class = shift;

	return CORE::sleep unless @_;
	$class->_validate_number($_[0]);
	return CORE::sleep if $_[0] <= -1;
	return $is_engaged ? do { $class->now($class->now + $_[0]); int($_[0]) } : CORE::sleep($_[0]);
}

sub time {
	my $class = shift;

	return $is_frozen ? $class->now : $class->tick;
}

1;

__END__

=head1 NAME

Time::StasisField - use science fiction to control time within your tests

=head1 SYNOPSIS

		use Test::More;
		use Time::StasisField (qw(now advance_time set_seconds_per_tick));

		Time::StasisField::engage;

		cmp_ok(
		  time - CORE::time,
		  '<=',
		  1,
		  "Perl's time() is within 1 second of CORE::time"
		);

		is( now, now, 'now is now' );

=head1 DESCRIPTION

something

=head1 AUTHOR

Aaron Cohen
