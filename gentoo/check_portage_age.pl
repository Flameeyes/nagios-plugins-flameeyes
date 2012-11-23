#!/usr/bin/perl
# -*- cperl -*-

=head 1 NAME

check_portage_age.pl - Check age of the portage tree

=head 1 APPLICABLE SYSTEMS

Any Gentoo Linux or derived system using Portage. While this could
probably work with pkgcore and paludis it has not been tested with
them and might require changes. Patches welcome.

=head1 LICENSE

Copyright © 2012 Diego Elio Pettenò <flameeyes@flameeyes.eu>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

use strict;
use Nagios::Plugin;
use Date::Parse;
use Time::Duration;

my $LICENSE = <<END;
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
END

my $np = Nagios::Plugin->new( shortname => "PORTAGE_AGE",
			      usage => "Usage: %s -w SECONDS -c SECONDS",
			      blurb => "Check Portage tree age (last sync)",
			      license => $LICENSE,
			      version => '0',
			      url => 'https://github.com/Flameeyes/nagios-plugins-flameeyes',
			    );

$np->add_arg( spec => "warning|w=i",
	      help => "Age from which to consider the sync tree old enough to warn.",
	      default => 60 * 60 * 24 * 3, # three days
	      label => [ 'SECONDS' ],
	    );

$np->add_arg( spec => "critical|c=i",
	      help => "Age from which to consider the sync tree too old.",
	      default => 60 * 60 * 24 * 7 * 2, # two weeks
	      label => [ 'SECONDS' ],
	    );

$np->getopts;

chomp(my $portdir = `portageq portdir`);

if ( $? == -1 ) {
    $np->nagios_die("Unable to execute portageq distdir: $!");
} elsif ( $? != 0 ) {
    $np->nagios_die("Error executing portageq");
}

if ( $portdir eq "" ) {
    $np->nagios_die("Unable to identify portdir");
}

open TIMESTAMP, ($portdir . "/metadata/timestamp.chk")
    or $np->nagios_die("Unable to open $portdir/metadata/timestamp.chk");
chomp(my $timestamp_str = readline(TIMESTAMP));
close(TIMESTAMP);

my $timestamp = str2time($timestamp_str);
my $difference = time() - $timestamp;
my $message = "last sync " . duration($difference) . " seconds ago";

my $code;
if ( $difference > $np->opts->critical ) {
    $code = CRITICAL;
} elsif ( $difference > $np->opts->warning ) {
    $code = WARNING;
} else {
    $code = OK;
}

$np->nagios_exit($code, $message);
