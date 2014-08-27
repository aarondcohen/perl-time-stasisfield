use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
	NAME                => 'Time::StasisField',
	AUTHOR              => q{Aaron Cohen <acohen@shutterstock.com>},
	VERSION_FROM        => 'lib/Time/StasisField.pm',
	ABSTRACT_FROM       => 'lib/Time/StasisField.pm',
	# LICENSE             => 'gpl_2',
	META_MERGE => {
		resources => {
			homepage => 'http://github.com/aarondcohen/perl-time-stasisfield',
			repository => 'git://github.com/aarondcohen/perl-time-stasisfield.git',
			bugtracker => 'http://github.com/aarondcohen/perl-time-stasisfield/issues',
		}
	},
);
