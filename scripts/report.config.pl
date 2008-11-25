#!/usr/bin/perl
#
# Name:
#	report.config.pl.

use strict;
use warnings;

use CGI::Uploader::Config;

# --------------------------------

my($config) = CGI::Uploader::Config -> new();

print 'dsn:         ', join(', ', @{$config -> dsn()}), ". \n";
print 'form_action: ', $config -> form_action(), ". \n";
print 'table_name:  ', $config -> table_name(), ". \n";
print 'tmpl_path:   ', $config -> tmpl_path(), ". \n";
