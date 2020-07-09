# NAME

Time::StasisField - control the flow of time

# VERSION

Version 0.01

# SYNOPSIS

_Time::StasisField_ provides a simple interface for controlling the flow of
time.  When the stasis field is disengaged, Perl's core time functions --
alarm, gmtime, localtime, sleep, and time -- behave normally, assuming that
time flows with the system clock.  When the stasis field is engaged, time
is guaranteed to advance at a predictable rate on every call.  For consistency,
all other time-related functions will use the modified time.

Example usage:

        use Time::StasisField;

        my @foos;

        @foos = map { Foo->new(create_time => time) } (1 .. 20);

        # All times will likely all look the same
        print $foos[-1]->create_time - $foos[0]->create_time;

        # The program will pause for 10 seconds
        sleep(10);

        # Time will be 10 seconds later
        print time;

        #Let's control time
        Time::StasisField->engage;

        @foos = map { Foo->new(create_time => time) } (1 .. 20);

        # All times will be distinct
        print $foos[-1]->create_time - $foos[0]->create_time;

        # Time will advance by 10 seconds
        sleep(10);

        # Fetch the current time without advancing it
        print Time::StasisField->now;


        Time::StasisField->seconds_per_tick(60);

        # Time is now 1 minute later
        print time;

        # Everything is back to normal
        Time::StasisField->disengage;

        # Hooray for system time
        print Time::StasisField->now;

# STASIS FIELD METHODS

## engage

Enable the stasis field, seizing control of the system time and setting now to
the time the field was enabled. If engage is called while the field is already
enabled, now is updated to the current system time.

## disenage

Disable the stasis field, returning control to the system time.

## is\_engaged

Return whether or not the stasis field is enabled.

## freeze

Time should stop advancing now.

## unfreeze

Time should continue advancing now.

## is\_frozen

Return whether or not time advances now.

# TIME METHODS

## now

Accessor for the current time.  The supplied time may be any valid number,
though now will always return an integer.  Falls back to the system time when
the stasis field is disengaged.

## seconds\_per\_tick

Accessor for the number of seconds time changes with each tick.  Supports
negative and subsecond deltas. Only works on time in an engaged stasis field.

## tick

Advance time by the value of seconds\_per\_tick, regardless of the freeze state.
Returns now.

# ACKNOWLEDGEMENTS

This module was made possible by [Shutterstock](http://www.shutterstock.com/)
([@ShutterTech](https://twitter.com/ShutterTech)).  Additional open source
projects from Shutterstock can be found at
[code.shutterstock.com](http://code.shutterstock.com/).

# AUTHOR

Aaron Cohen, `<aarondcohen at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-time-stasisfield at rt.cpan.org`, or through
the web interface at [https://github.com/aarondcohen/perl-time-stasisfield/issues](https://github.com/aarondcohen/perl-time-stasisfield/issues).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc Time::StasisField

You can also look for information at:

- Official GitHub Repo

    [https://github.com/aarondcohen/perl-time-stasisfield](https://github.com/aarondcohen/perl-time-stasisfield)

- GitHub's Issue Tracker (report bugs here)

    [https://github.com/aarondcohen/perl-time-stasisfield/issues](https://github.com/aarondcohen/perl-time-stasisfield/issues)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Time-StasisField](http://cpanratings.perl.org/d/Time-StasisField)

- Official CPAN Page

    [http://search.cpan.org/dist/Time-StasisField/](http://search.cpan.org/dist/Time-StasisField/)

# LICENSE AND COPYRIGHT

Copyright 2013 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
