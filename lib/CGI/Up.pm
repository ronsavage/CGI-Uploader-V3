package CGI::Up;

use strict;
use warnings;

use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has form_fields => (is => 'rw', required => 0, isa => 'ArrayRef');
has generate    => (is => 'rw', required => 0, isa => 'HashRef');
has store       => (is => 'rw', required => 0, isa => 'HashRef');
has upload      => (is => 'rw', required => 0, isa => 'HashRef');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

}	# End of BUILD.

# -----------------------------------------------

sub run
{
	my($self) = @_;

} # End of run.

# -----------------------------------------------

1;

=pod

=head1 NAME

CGI::Uploader - Manage CGI uploads using an SQL database

=head1 Synopsis

	my($u) = CGI::Uploader -> new(upload => {file_name_1 => {} });

=head1 Description

C<CGI::Uploader> is a pure Perl module.

=head1 Warning: V 2 'v' V 3

The API for C<CGI::Uploader> version 3 is not compatible with the API for version 2.

This is because V 3 is a complete rewrite of the code, taking in to account all the things
learned from V 2.

=head1 Constructor and initialization

new(...) returns a C<CGI::Uploader> object.

This is the class's contructor.

Options:

=over 4

=item form_fields => {}

The keys of this hashref are CGI form field names, where the fields are of type 'file'.

Each key points to a hashref which has up to 3 keys:

=over 4

=item generate => {}

=item store => {}

=item upload => {}

=back

Yes, that's right, they are exactly the same keys as documented immediately below.

The point is that the next 3 keys are globals, in that they apply to every file uploaded.

But the 3 keys above in %$form_fields can be used to over-ride these global values on a
file-by-file basis.

For example:

	CGI::Uploader -> new
	(
	form_fields => # Optional.
		{
		file_name_1 =>
			{ # Options for file_name_1, over-riding the globals.
			generate => {...}, # Optional.
			store    => {...}, # Optional.
			upload   => {...}, # Optional.
			},
		file_name_2 =>
			{ # Options for file_name_2, over-riding the globals.
			},
		},
	generate => {...}, # Optional.
	store    => {...}, # Optional.
	upload   => {...}, # Optional.
	);

Obviously, you have to supply I<some> options, either globally, locally, or both.

=item generate => {}

The keys of this hashref are CGI form field names, where the fields are of type 'file'.

Each key points to a hashref that specifies how to generate files, e.g. thumbnails, from the uploaded file.

=item store => {}

The keys of this hashref are CGI form field names, where the fields are of type 'file'.

Each key points to a hashref that specifies how to store meta-data for the uploaded file.

=item upload => {}

The keys of this hashref are CGI form field names, where the fields are of type 'file'.

Each key points to a hashref that specifies which CGI form field names to process.

=back

=head1 Changes

See Changes and Changelog.ini. The latter is machine-readable, using Module::Metadata::Changes.

=head1 Public Repository

V 3 is available from github: git:github.com/ronsavage/cgi--uploader.git

=head1 Authors

V 2 was written by Mark Stosberg <mark@summersault.com>.

V 3 is by Mark Stosberg and Ron Savage <ron@savage.net.au>.

Ron's home page: http://savage.net.au/index.html

=cut
