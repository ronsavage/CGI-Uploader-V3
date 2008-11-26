#!/usr/bin/perl
#
# Name:
#	create.table.pl.

use strict;
use warnings;

use CGI::Uploader::Test;

# --------------------------------

my($creator) = CGI::Uploader::Test -> new();

print "Deleting files for database 'test'. \n";

$creator -> delete(2);

print "Finished deleting files. \n";
print "------------------------ \n";
