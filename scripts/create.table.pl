#!/usr/bin/perl
#
# Name:
#	create.table.pl.

use strict;
use warnings;

use CGI::Up::Test;

# --------------------------------

my($creator) = CGI::Up::Test -> new();

print "Creating tables for database 'test'. \n";

$creator -> drop_table();
$creator -> create_table();

print "Finished creating tables. \n";
print "------------------------- \n";
