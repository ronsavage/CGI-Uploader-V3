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
 file_scheme => 'md5',
 path        => '/tmp',
 records     =>
 {
	 22  =>
	 [
	  {
		  options =>
		  {
			  width  => 300,
			  height => 200,
		  },
	  },
	  {
		  options =>
		  {
			  width  => 200,
			  height => 100,
		  },
	  },
	 ],
	 21 =>
	 [
	  {
		  options =>
		  {
			  width  => 800,
			  height => 666,
		  },
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
