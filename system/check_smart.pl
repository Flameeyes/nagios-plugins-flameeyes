#!/usr/bin/perl
# -*- cperl -*-

=head 1 NAME

check_smart.pl - Check health status of S.M.A.R.T. drives

=head 1 APPLICABLE SYSTEMS

This script has been developed to work with smartmontool's smartctl
command, and with various types of controllers.

It has been tested under Gentoo Linux and CentOS 5.8, with both
standard SATA and HP CCISS controlles.

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

my $np = Nagios::Plugin->new( shortname => "SMART",
			      usage => "Usage: %s [--sudo] [--smartctl PATH] [--device TYPE] device",
			      blurb => "Check health status of S.M.A.R.T. drives",
			      license => $LICENSE,
			      version => '0',
			      url => 'https://github.com/Flameeyes/nagios-plugins-flameeyes',
			    );

$np->add_arg( spec => "sudo|s",
	      help => "Use 'sudo' to execute smartctl."
	    );
$np->add_arg( spec => "smartctl|S=s",
	      help => "Use the smartctl command found at PATH.",
	      default => "/usr/sbin/smartctl",
	      label => [ "PATH" ],
	    );
$np->add_arg( spec => "device|d=s",
	      help => "Specifies the type of device.",
	      label => [ "TYPE" ]
	    );

$np->getopts;

my $cmd = $np->opts->smartctl;
$cmd = "sudo -n $cmd" if $np->opts->sudo;

my $params = "-H";
if ( defined($np->opts->device) ) {
  $params .= " -d " . $np->opts->device;
}

unless($ARGV[0]) {
  $np->nagios_die("Missing target device");
}

alarm $np->opts->timeout;
$cmd = "$cmd $params $ARGV[0]";
my $output = `$cmd`;

if ( $? == -1 ) {
  $np->nagios_die("Unable to execute $np->opts->smartctl: $!");
} elsif ( $? != 0 ) {
  $np->nagios_die("Error executing $cmd");
}

unless ( $output =~ /\nSMART (?:Health Status|overall-health self-assessment test result): (.*)\n/ ) {
  $np->nagios_die("Unable to identify health status results");
}

if ( $1 == "PASSED" ) {
  $np->nagios_exit(OK, '');
} else {
  $np->nagios_exit(CRITICAL, $1);
}
