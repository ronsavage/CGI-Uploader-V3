#!/usr/bin/perl
#
# Name:
# use.cgi.uploader.v3.pl.
#
# Note:
# Need use lib here because CGI scripts don't have access to
# the PerlSwitches used in httpd.conf.

use lib '/home/ron/perl.modules/CGI-Uploader/lib';
use strict;
use warnings;

use CGI::Uploader::Test;

# ----------------

CGI::Uploader::Test -> new() -> use_cgi_uploader_v3();
