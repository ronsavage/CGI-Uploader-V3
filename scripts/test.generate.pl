#!/usr/bin/perl

use strict;
use warnings;

use CGI::Uploader::Config;
use CGI::Up;
use DBI;

# ------------------------

my($config) = CGI::Uploader::Config -> new();
my($dbh)    = DBI -> connect(@{$config -> dsn()});
my($up)     = CGI::Up -> new(dbh => $dbh);
my($data)   = $up -> generate
(
 records =>
 {
	 1  =>
	 [
	  {
		  width  => 200,
		  height => 400,
	  },
	  {
		  width  => 400,
		  height => 800,
	  },
	 ],
	 21 =>
	 [
	  {
		  width  => 500,
		  height => 900,
	  },
	 ],
 },
 sequence_name => 'uploads_id_seq',
 table_name    => 'uploads',
);

my($id);

for $id (sort keys %$data)
{
	print "id $id => [", join(', ', @{$$data{$id} }), "]. \n";
}
