#!/usr/bin/perl
#
# Name:
#	create.table.pl.

use strict;
use warnings;

use CGI::Uploader::Test;

# --------------------------------

my($creator) = CGI::Uploader::Test -> new();

print "Creating tables for database 'test'. \n";

$creator -> drop_table();
$creator -> create_table();

print "Finished creating tables. \n";
print "------------------------- \n";
