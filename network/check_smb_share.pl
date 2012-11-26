#!/usr/bin/perl
# -*- cperl -*-

=head 1 NAME

check_smb_share.pl - Check for accessibility of SMB shares

=head 1 APPLICABLE SYSTEMS

This script has been developed to verify the status of a SMB share as
exposed by either Samba or Windows.

It has been developed on Gentoo Linux and tested on CentOS 5.8

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
use Filesys::SmbClient;

my $LICENSE = <<END;
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
END

my $np = Nagios::Plugin->new( shortname => "SMB SHARE",
			      usage => "Usage: %s [-u USERNAME] [-p PASSWORD] [-w WORKGROUP] -H HOSTNAME [-P PATH] [-W] [-D] SHARE",
			      blurb => "Check for accessibility of SMB shares",
			      license => $LICENSE,
			      version => '0',
			      url => 'https://github.com/Flameeyes/nagios-plugins-flameeyes',
			    );

$np->add_arg( spec => "username|u=s",
	      help => "Provides the username to use for connection.",
	      label => [ "USERNAME" ]
	    );

$np->add_arg( spec => "password|p=s",
	      help => "Provides the password to use for connection.",
	      label => [ "PASSWORD" ]
	    );

$np->add_arg( spec => "workgroup|w=s",
	      help => "Provides the workgroup to use for connection.",
	      label => [ "WORKGROUP" ]
	    );

$np->add_arg( spec => "hostname|H=s",
	      help => "Select the hostname to connect to.",
	      label => [ "HOSTNAME" ]
	    );

$np->add_arg( spec => "path|P=s",
	      help => "Select a specific directory or file to check for.",
	      label => [ "PATH" ],
	      default => "",
	    );

$np->add_arg( spec => "writable|W",
	      help => "Check that the given path is writable.",
	    );

$np->add_arg( spec => "directory|D",
	      help => "The given path is one to a directory.",
	    );

$np->getopts;

unless($ARGV[0]) {
  $np->nagios_die("Missing share name");
}

unless($np->opts->hostname) {
  $np->nagios_die("Missing server name");
}

# Prepare the parameters if so given on the command line
my %params;
$params{username} = $np->opts->username if defined($np->opts->username);
$params{password} = $np->opts->password if defined($np->opts->password);
$params{workgroup} = $np->opts->workgroup if defined($np->opts->workgroup);

my $smb = new Filesys::SmbClient(%params)
  or $np->nagios_exit(CRITICAL, "Cannot create connection: $!");

my $sharepath = "smb://" . $np->opts->hostname . "/" . $ARGV[0];

my $handle = $smb->opendir($sharepath)
  or $np->nagios_exit(CRITICAL, "Cannot open share root: $!");
$smb->close($handle);

my $subpath = $np->opts->path;
$subpath =~ s|\\|/|g;
$subpath = $sharepath . "/" . $subpath;

my @stat = $smb->stat($subpath) or
  $np->nagios_exit(CRITICAL, "Cannot stat path: $!");

if ( $np->opts->writable ) {
  if ( $np->opts->directory ) {
    $np->nagios_exit(WARNING, "Writable directory check is currently non-functional.");
#    my $tmpfile = $subpath . "/check_smb_share";
#    printf "%s\n", $tmpfile;
#
#    $smb->open($tmpfile, 0666)
#      or $np->nagios_exit(WARNING, "Unable to write to path: $!");
#
#    $smb->unlink($tmpfile);
  } else {
    $smb->open(">>" . $subpath, 0666)
      or $np->nagios_exit(WARNING, "Unable to write to path: $!");
  }
}

$np->nagios_exit(OK, '');
