package CGI::Uploader::Source::Default;

use strict;
use warnings;

use File::Basename;
use File::Copy; # For copy.
use File::Temp 'tempfile';

use HTTP::BrowserDetect;

use MIME::Types;

use Squirrel;

extends 'CGI::Uploader::Source';

our $VERSION = '2.90_03';

# -----------------------------------------------

has query => (is => 'rw', required => 0, predicate => 'has_query', isa => 'Any', default => sub{CGI -> new()});

# -----------------------------------------------

sub upload
{
	my($self, $field_name) = @_;

	# Strip off the volume/path info, if any, from the client's file name.

	my($client_os) = $^O; # Actually, server OS by default.
	my($browser)   = HTTP::BrowserDetect -> new();
	$client_os     = 'MSWin32' if ($browser -> windows() );
	$client_os     = 'MacOS'   if ($browser -> mac() );
	$client_os     = 'Unix'    if ($browser->macosx() );

	File::Basename::fileparse_set_fstype($client_os);

	my($client_file_name)  = $self -> query() -> param($field_name);
	my($file_name)         = File::Basename::fileparse($client_file_name, []);
	my($fh)                = $self -> query() -> upload($field_name);

	if (! $fh && $self -> query() -> cgi_error() )
	{
		confess $self -> query() -> cgi_error();
	}

	if (! $fh)
	{
		confess 'Unable to generate a file handle';
	}
	my($mime_type) = $self -> query() -> uploadInfo($fh);

	if ($mime_type)
	{
		$mime_type = $$mime_type{'Content-Type'};
	}

	# Determine the file extension, if any.

	my($mime_types) = MIME::Types -> new();
	my($type)       = $mime_types -> type($mime_type);
	my(@extension)  = $type ? $type -> extensions() : ();
	my($client_ext) = ($file_name =~ m/\.([\w\d]*)?$/);
	$client_ext     = '' if (! $client_ext);
	my($server_ext) = '';

	if ($extension[0])
	{
		# If the client extension is one recognized by MIME::Type, use it.

		if (defined($client_ext) && (grep {/^$client_ext$/} @extension) )
		{
			$server_ext = $client_ext;
		}
	}
	else
	{
		# If it is a provided extension but not a MIME::Type extension, use it.

		$server_ext = $client_ext;
	}

	my($temp_fh, $temp_file_name) = tempfile('CGIuploaderXXXXX', DIR => $self -> temp_dir(), UNLINK => 1);
	binmode($fh);
	copy($fh, $temp_file_name) || confess "Unable to create temp file '$temp_file_name': $!";

	return
	{
		client_file_name => $client_file_name,
		extension        => $server_ext,
		mime_type        => $mime_type || '',
		server_temp_name => $temp_file_name,
		size             => (stat $temp_file_name)[7],
	};

} # End of upload.

# -----------------------------------------------

1;

=pod

=head1 NAME

CGI::Uploader::Source::Default - Default uploader

=head1 Synopsis


=head1 Description

C<CGI::Uploader::Source::Default> is a pure Perl module.

=head1 Public Repository

V 3 is available from github: git:github.com/ronsavage/cgi--uploader.git

=head1 Authors

V 2 was written by Mark Stosberg <mark@summersault.com>.

V 3 was written by Ron Savage <ron@savage.net.au>.

Ron's home page: http://savage.net.au/index.html

=head1 Licence

Artistic.

=cut
