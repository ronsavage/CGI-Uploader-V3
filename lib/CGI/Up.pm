package CGI::Up;

use strict;
use warnings;

use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has generate => (is => 'rw', required => 0, predicate => 'has_generate', isa => 'HashRef');
has store    => (is => 'rw', required => 1, isa => 'HashRef');

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

	my($store) = $self -> store();

	if (! $$store{'column_map'})
	{
		$$store{'column_map'} =
		{
			client_file_name => 'client_file_name',
			date_stamp       => 'date_stamp',
			extension        => 'extension',
			height           => 'height',
			id               => 'id',
			mime_type        => 'mime_type',
			parent_id        => 'parent_id',
			server_file_name => 'server_file_name',
			size             => 'size',
			width            => 'width',
		};

		$self -> store($store);
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

These arrayrefs contain either 2 or 4 entries (since I<generate> is optional and I<store> is mandatory):

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

Being mandatory means the uploaded file's meta-data I<must> be stored somewhere, but making the I<generate>
key optional means you do not have to transform uploaded files in any way, if you don't wish to.

=back

=head1 The I<generate> key

The I<generate> key points to an arrayref of hashrefs.

Use multiple elements to store multiple versions of the uploaded file.

Each hashref contains the following keys:

=over 4

=item One rainy day, design this section of the code, and document it

=back

=head1 The I<store> key

The I<store> key points to an arrayref of hashrefs.

Use multiple elements to store multiple sets of meta-data, all based on the same uploaded file.

Each hashref contains 1 .. 5 of the following keys:

=over 4

=item column_map => {...}

This hashref maps column_names used by C<CGI::Uploader> to column names used by your storage.

I<Column_map> is optional.

The default column_map is:

	{
	client_file_name => 'client_file_name',
	date_stamp       => 'date_stamp',
	extension        => 'extension',
	height           => 'height',
	id               => 'id',
	mime_type        => 'mime_type',
	parent_id        => 'parent_id',
	server_file_name => 'server_file_name',
	size             => 'size',
	width            => 'width',
	}

If you supply a different column map, the values on the right-hand side are the ones you change.

Points to note:

=over 4

=item Omitting keys

If you omit any keys from your map, the corresponding meta-data will not be stored.

=item Client file name

The client_file_name is the name supplied by the web client to C<CGI::Uploader>. It may
I<or may not> have path information prepended, depending on the web client.

=item Date stamp

The value of the function I<now()> will be stored in this field.

I<Date_stamp> has an underscore in it in case your database regards datastamp as a reserved word.

=item Extension

This is provided by the C<File::Basename> module.

The extension is a string I<without> the leading dot.

If an extension cannot be determined, the value will be '', the empty string.

=item Height

If the uploaded or generated file is recognized as an image, this field will hold its height.

For non-image files, the value will be 0.

=item Id

The id is (presumably) the primary key of your table.

In the case of Postgres, it will be populated by the sequence named with the I<sequence_name> key, below.

=item MIME type

This is provided by the I<MIME::Types> module, if it can determine the type.

If not, it is '', the empty string.

=item Parent id

This is populated when a file is generated from the uploaded file. It's value will be the id of
the upload file's record.

For the uploaded file itself, the value will be 0.

=item Server file name

The server_file_name is the name under which the file is finally stored on the file system
of the web server. It is not the temporary file name used during the upload process.

=item Size

This is the file size in bytes.

=item Width

If the uploaded or generated file is recognized as an image, this field will hold its width.

For non-image files, the value will be 0.

=back

=item dbh => $dbh

This is a database handle for use by the default manager class C<CGI::Uploader::Store::Manager>
discussed below, under I<manager>.

This key is optional if you use the I<manager> key, since in that case you can use your own
code as the storage manager.

If you do provide the I<dbh> key, it is passed in to your manager just in case you need it.

Also, if you provide I<dbh>, the I<dsn> key, below, is ignored.

If you do not provide the I<dbh> key, the default manager uses the I<dsn> arrayref to create an
object of type C<DBIx::Simple>, and uses its I<dbh>.

=item dsn => [...]

This key is ignored if you provide a I<dbh> key.

This key is mandatory when you do not provide a I<dbh> key.

The elements in the arrayref are:

=over 4

=item A connection string

E.g.: 'dbi:Pg:dbname=test'

This element is mandatory.

=item A username string

This element is mandatory, even if it's just the empty string.

=item A password string

This element is mandatory, even if it's just the empty string.

=item A connection attributes hashref

This element is optional.

=back

The default manager class calls DBIx::Simple -> new(@$dsn) to connect to the database, i.e. in order
to generate a I<dbh>, when you don't provide a I<dbh> key.

=item manager => 'String'

This is the name of a class which will manage the transfer of meta-data to storage.

This key is optional.

If you provide your own class name here, C<CGI::Uploader> will create an instance of this class
by calling new(meta_data => $meta_data, %{...}).

Here, $meta_data will be a hashref of options, and %{...} will be one of the hashrefs in the arrayref
pointed to by I<store>.

Each hashref in the latter arrayref will cause another instance of this class to be instantiated and used.

If you do not provide the I<dbh> key, $dbh will be '', the empty string.

The same goes for $table_name and $sequence_name.

Note: They are empty strings and not undef because Moose likes things that way for required parameters.

In the case where you provide the I<manager> key, your class is responsible for saving the meta-data.

See the next section for the definition of the meta-data.

If you do not provide the I<manager> key, C<CGI::Uploader> will create an instance of a
built-in class C<CGI::Uploader::Store::Manager> by calling new(meta_data => $meta_data, %{...}).

$meta_data and %{...} are described a few line above.

In this case, the I<dbh> and I<table_name> keys are obviously mandatory (along with I<sequence_name> for
Postgres), and the default store manager will generate and execute SQL to save the meta-data.

=item sequence_name => 'String'

This is the name of the sequence used to generate values for the primary key of the table.

You would normally only need this when using Postgres.

This key is optional if you use the I<manager> key, since in that case you can use your own
code as the storage manager. If you do provide the I<sequence_name> key, it is passed in to your manager
just in case you need it.

This key is mandatory if you use Postgres and do not use the I<manager> key, since without the I<manager> key
I<sequence_name> must be passed in to the default manager C<CGI::Uploader::Store::Manager>.

=item table_name => 'String'

This is the name of the table into which to store the meta-data.

This key is optional if you use the I<manager> key, since in that case you can use your own
code as the storage manager. If you do provide the I<table_name> key, it is passed in to your manager
just in case you need it.

This key is mandatory if you do not use the I<manager> key, since without the I<manager> key
I<table_name> must be passed in to the default manager C<CGI::Uploader::Store::Manager>.

=back

The simplest option, then, is to use

	store => [{dbh => $dbh, table_name => 'uploads'}]

and let C<CGI::Uploader> do all the work.

For Postgres, make that

	store => [{dbh => $dbh, sequence_name => 'uploads_id_seq', table_name => 'uploads'}]

=head1 Meta-data

Meta-data is a hashref, with these keys:

=over 4

=back

=head1 Changes

See Changes and Changelog.ini. The latter is machine-readable, using Module::Metadata::Changes.

=head1 Public Repository

V 3 is available from github: git:github.com/ronsavage/cgi--uploader.git

=head1 Authors

V 2 was written by Mark Stosberg <mark@summersault.com>.

V 3 is by Mark Stosberg and Ron Savage <ron@savage.net.au>.

Ron's home page: http://savage.net.au/index.html

=head1 Licence

Artistic.

=cut
