Flameeyes's custom Nagios/Icinga plugins
========================================

[![Flattr this!](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/thing/1014927)

This repository has been created because I feel the need for more
structure to push my personal Nagios plugins than just publishing them
to a website, and because I feel that there is no reason why I should
keep said plugins all by myself.

Please feel free to fork and send pull request for any enhacement or
fix you come up with.

License
-------

Each plugin will provide its own license header to make it clear under
which license it's released under. Most of them you'll see having a
MIT license, which basically is an all-permissive license. If
different licenses are used, it's usually because the plugin is
derived from another one that was published under a different license.

Dependencies
------------

All Perl-based plugins will require Nagios::Plugin at the very least,
as that implements the basic Nagios API in a flexible way.

 * check_smart.pl
   - smartmontools (smartctl), is needed to access SMART data;
   - sudo, optional for running from non-root user.
 * check_openrc.pl
   - openrc itself.
 * `check_portage_age.pl`
   - Date::Parse;
   - Time::Duration.

