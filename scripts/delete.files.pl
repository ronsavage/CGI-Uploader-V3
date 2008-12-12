#!/usr/bin/perl
#
# Name:
#	delete.files.pl.

use lib '/home/ron/perl.modules/CGI-Uploader/lib';
use strict;
use warnings;

use CGI::Uploader::Test;

# --------------------------------

my($creator) = CGI::Uploader::Test -> new();

print "Deleting files for database 'test'. \n";

my($result) = $creator -> delete(1);

my($row);

for $row (@$result)
{
	print map{"$_ => $$row{$_}. \n"} sort keys %$row;
}

print "Finished deleting files. \n";
print "------------------------ \n";
