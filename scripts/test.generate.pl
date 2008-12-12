#!/usr/bin/perl

use strict;
use warnings;

use CGI::Uploader::Config;
use CGI::Uploader;
use DBI;
use CGI::Uploader::Transform::ImageMagick;
use CGI::Uploader::Transform::Imager;

# ------------------------

my($config) = CGI::Uploader::Config -> new();
my($dbh)    = DBI -> connect(@{$config -> dsn()});
my($up)     = CGI::Uploader -> new(dbh => $dbh);
my($data)   = $up -> generate
(
 file_scheme => 'md5',
 path        => '/tmp',
 records     =>
 {
	 1  =>
	 [
	  CGI::Uploader::Transform::ImageMagick::transformer(width => 500, height => 400),
	  CGI::Uploader::Transform::Imager::transformer(xpixels => 500, ypixels => 400),
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
