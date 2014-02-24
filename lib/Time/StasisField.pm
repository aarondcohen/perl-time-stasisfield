package Time::StasisField;

use strict;
use warnings;

use Exporter (qw{import});
use POSIX (qw{SIGALRM});

our $VERSION = '0.01';

our @EXPORT_OK  = qw{
	advance_time
	disengage_stasis
	engage_stasis
	freeze_time
	now
	seconds_per_tick
	set_now
	set_seconds_per_tick
	unfreeze_time
};
our %EXPORT_TAGS = (all => \@EXPORT_OK);

############################
# Core Overrides
############################

BEGIN {
	*CORE::GLOBAL::alarm = sub ($) { goto &Time::StasisField::alarm };
	*CORE::GLOBAL::gmtime = sub (;$) { goto &Time::StasisField::gmtime };
	*CORE::GLOBAL::localtime = sub (;$) { goto &Time::StasisField::localtime };
	*CORE::GLOBAL::sleep = sub (;$) { goto &Time::StasisField::sleep };
	*CORE::GLOBAL::time = sub () { goto &Time::StasisField::time };
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

# scenario 1:
# set alarm
# engage
# advance past alarm
# => alarm should trigger only on advancement
#
# scenario 2:
# engage
# set alarm
# disengage
# alarm should trigger only after N seconds

############################
# Helper Functions
############################

sub _validate_number($) {
	#Make sure the value is numeric
	use warnings (FATAL => 'all');
	no warnings ("void");
	int($_[0]);
}

sub _trigger_alarm() {
	return
	  if ! $is_alarm_set
	  || $current_time < $alarm_time;

	$is_alarm_set = 0;
	kill SIGALRM, $$;
}

############################
# API
############################

sub now();
sub engage();
sub engage_stasis();
sub disengage();
sub disengage_stasis();
sub advance($);
sub advance_time($);
sub set_now($);


sub engage() {
	CORE::alarm(0) if $is_alarm_set;
	$current_time = CORE::time;
	$is_engaged = 1;
	_trigger_alarm;
	return;
}

sub disengage() {
	$current_time = CORE::time;
	$is_engaged = 0;
	_trigger_alarm;
	CORE::alarm($alarm_time - CORE::time) if $is_alarm_set;
	return;
}

*engage_stasis = sub { goto &engage };
*disengage_stasis = sub { goto &disengage };

sub advance($) {
	return CORE::time unless $is_engaged;

	_validate_number($_[0]);
	$current_time += $_[0];
	_trigger_alarm;

	return now;
}

*advance_time = sub { goto &advance };

sub now() { $is_engaged ? int($current_time) : CORE::time }

sub set_now($) {
	if ($is_engaged) {
		_validate_number($_[0]);
		$current_time = $_[0];
		_trigger_alarm;
	} else {
		$current_time = CORE::time;
	}

	return now;
}

sub seconds_per_tick() { $seconds_per_tick }

sub set_seconds_per_tick($) {
	_validate_number($_[0]);
	$seconds_per_tick = $_[0];
}

sub freeze()   { $is_frozen = 1 }
sub unfreeze() { $is_frozen = 0 }

*freeze_time = sub { goto &freeze };
*unfreeze_time = sub { goto &unfreeze };

sub alarm(;$) {
	my $offset = @_ ? $_[0] : $_;

	_validate_number($offset);

	my $previous_alarm_time_remaining =
		! defined $alarm_time ? $alarm_time :
		$is_alarm_set ? $alarm_time - now : 0;
	$alarm_time = $offset > -1 ? now + int($offset) : undef;
	$is_alarm_set = defined $alarm_time && $offset >= 1;

	return $is_engaged ? $previous_alarm_time_remaining : CORE::alarm($_[0]);
}

sub gmtime(;$) {
	use warnings (FATAL => 'all');
	CORE::gmtime(@_ ? $_[0] : time);
}

sub localtime(;$) {
	use warnings (FATAL => 'all');
	CORE::localtime(@_ ? $_[0] : time);
}

sub sleep(;$) {
	return CORE::sleep unless @_;
	_validate_number($_[0]);
	return CORE::sleep if $_[0] <= -1;
	return $is_engaged ? do { advance($_[0]); int($_[0]) } : CORE::sleep($_[0]);
}

sub time() { $is_frozen ? now : advance seconds_per_tick }

1;
