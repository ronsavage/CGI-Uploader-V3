package CGI::Up;

use strict;
use warnings;

use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has form_fields => (is => 'rw', required => 0, predicate => 'has_form_fields', isa => 'HashRef');
has generate    => (is => 'rw', required => 0, predicate => 'has_generate',    isa => 'HashRef');
has store       => (is => 'rw', required => 0, predicate => 'has_store',       isa => 'HashRef');
has upload      => (is => 'rw', required => 0, predicate => 'has_upload',      isa => 'HashRef');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Test 1: One parameter, at least, must be specified.

	if (! $self -> has_form_fields() || $self -> has_generate() || $self -> has_store() || $self -> has_upload)
	{
		confess 'You must provide at least one of form_fields, generate, store or upload';
	}

	# Test 2: One CGI form field name, at least must be specified,
	# using either form_fields => {} or upload => {}.

	my(@field_names);

	if ($self -> has_form_fields() )
	{
		@field_names = keys %{$self -> form_fields()};
	}

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

	CGI::Uploader -> new
	(
	form_field_1 =>
	[
		generate => [...], # Optional.
		store    => [...], # Mandatory.
	],
	form_field_2 =>
	[
		generate => [...], # Optional.
		store    => [...], # Mandatory.
	],
	);

=head1 Description

C<CGI::Uploader> is a pure Perl module.

=head1 Warning: V 2 'v' V 3

The API for C<CGI::Uploader> version 3 is not compatible with the API for version 2.

This is because V 3 is a complete rewrite of the code, taking in to account all the things
learned from V 2.

=head1 Constructor and initialization

C<new(...)> returns a C<CGI::Uploader> object.

This is the class's contructor.

You must pass a hash to C<new(...)>.

The keys of this hash are CGI form field names (where the fields are of type I<file>).

Each key points to an arrayref of options which specifies how to process the field.

These arrayrefs contain either 2 or 4 entries:

Options:

=over 4

=item generate => [...]

Each element of the arrayref pointed to by I<generate> specifies how to generate 1 file based on the uploaded file.

Use multiple elements to generate multiple files, all based on the same uploaded file.

See below for details of I<generate>.

This key is optional.

=item store => [...]

Each element of the arrayref pointed to by I<store> specifies how to store 1 set of meta-data for the uploaded file.

Use multiple elements to store multiple sets of meta-data, all based on the same uploaded file.

In practice, of course, you would normally only store the meta-data once, but an arrayref has been
deliberately chosen to allow you to store the meta-data in more than one place.

Also, having both I<generate> and I<store> point to arrayrefs reduces the possibility of confusion.

See below for details of I<store>.

This key is mandatory.

=back

=head1 The I<generate> key

=head1 The I<store> key

=head1 Changes

See Changes and Changelog.ini. The latter is machine-readable, using Module::Metadata::Changes.

=head1 Public Repository

V 3 is available from github: git:github.com/ronsavage/cgi--uploader.git

=head1 Authors

V 2 was written by Mark Stosberg <mark@summersault.com>.

V 3 is by Mark Stosberg and Ron Savage <ron@savage.net.au>.

Ron's home page: http://savage.net.au/index.html

=cut
