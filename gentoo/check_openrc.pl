#!/usr/bin/perl
# -*- cperl -*-

=head 1 NAME

check_openrc.pl - Check status of started services with OpenRC

=head 1 APPLICABLE SYSTEMS

Any system running OpenRC as init system — namely Gentoo Linux systems
(and derived distributions).

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

my $LICENSE = <<END;
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
END

my $np = Nagios::Plugin->new( shortname => "OPENRC",
			      usage => "Usage: %s [--stopped-critical] <list of runlevels>",
			      blurb => "Check services status on OpenRC",
			      license => $LICENSE,
			      version => '0',
			      url => 'https://github.com/Flameeyes/nagios-plugins-flameeyes',
			    );

$np->add_arg( spec => "stopped-critical|s",
	      help => "Consider the presence of stopped services critical."
	    );

$np->getopts;

my $cmd = "rc-status -C " . join(' ', @ARGV);
my $output = `$cmd`;

if ( $? == -1 ) {
  $np->nagios_die("Unable to execute rc-status: $!");
} elsif ( $? != 0 ) {
  $np->nagios_die("Error executing rc-status");
}

my @stopped;
my @crashed;
my @started;

foreach my $line (split('\n', $output)) {
    if ( $line =~ /^\s([^\s]+)\s+.\s+([^\s]+)\s+.$/ ) {
	my $service = $1;
	my $status = $2;
	if ( $status eq 'stopped' ) {
	    push(@stopped, $service);
	} elsif ( $status eq 'crashed' ) {
	    push(@crashed, $service);
	} elsif ( $status eq 'started' ) {
	    push(@started, $service);
	} else {
	    $np->nagios_die("Service $service has unknwon status $status");
	}
    }
}

my $code = OK;
my $message = "";
my $extmessage = "Running services: " . join(', ', @started);

if ( scalar(@stopped) > 0 ) {
    $code = $np->opts->get("stopped-critical") ? CRITICAL : WARNING;
    $message .= "STOPPED " . join(', ', @stopped) . " ";
}

if ( scalar(@crashed) > 0 ) {
    $code = CRITICAL;
    $message .= "CRASHED " . join(', ', @stopped);
}

$np->nagios_exit($code, $message . "\n" . $extmessage);
