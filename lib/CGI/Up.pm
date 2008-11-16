package CGI::Up;

use strict;
use warnings;

use File::Copy; # For copy.
use File::Spec;
use File::Temp 'tempfile';

use Params::Validate ':all';

use Squirrel;

our $VERSION = '2.90';

# -----------------------------------------------

has query    => (is => 'rw', required => 0, predicate => 'has_query', isa => 'Any');
has temp_dir => (is => 'rw', required => 0, predicate => 'has_temp_dir', isa => 'Any');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Ensure a query object is available.

	if ($self -> has_query() )
	{
		my($ok)   = 0;
		my(@type) = (qw/Apache::Request Apache2::Request CGI/);

		my($type);

		for $type (@type)
		{
			if ($self -> query() -> isa($type) )
			{
				$ok = 1;

				last;
			}
		}

		if (! $ok)
		{
			confess 'Your query object must be one of these types: ' . join(', ', @type);
		}
	}
	else
	{
		require CGI;

		$self -> query(CGI -> new() );
	}

	# Ensure a temp dir name is available.

	if (! $self -> has_temp_dir() )
	{
		$self -> temp_dir(File::Spec -> tmpdir() );
	}

}	# End of BUILD.

# -----------------------------------------------

sub save
{
	my($self, $path, $temp_file_name, $meta_data) = @_;
	my($server_file_name) = File::Spec -> catdir($path, "$$meta_data{'id'}.xxx");

	copy($temp_file_name, $server_file_name);

	warn "=> Copy from $temp_file_name to $server_file_name";

	return $server_file_name;

} # End of save.

# -----------------------------------------------

sub upload
{
	my($self, %field) = @_;

	# Loop over the CGI form fields.

	my($field_name, $field_option);
	my($meta_data);
	my($store, $store_option);

	for $field_name (keys %field)
	{
		$field_option = $field{$field_name};

		$self -> validate_field_options
		(
		 $field_name,
		 generate => $$field_option{'generate'},
		 store    => $$field_option{'store'},
		);

		# Perform the upload for this field.

		my($temp_fh, $temp_file_name) = tempfile('CGIuploaderXXXXX', UNLINK => 1, DIR => $self -> temp_dir() );
		$meta_data                    = $self -> work($field_name, $temp_file_name);
		my($store_count)              = 0;

		# Loop over all store options.

		for $store_option (@{$$field_option{'store'} })
		{
			$store_count++;

			# Ensure a dbh or dsn was specified.

			if (! ($$store_option{'dbh'} || $$store_option{'dsn'}) )
			{
				confess "You must provide at least one of dbh and dsn for form field '$field_name'";
			}

			$store_option = $self -> validate_store_options
			(
			 column_map    => $$store_option{'column_map'},
			 dbh           => $$store_option{'dbh'},
			 dsn           => $$store_option{'dsn'},
			 path          => $$store_option{'path'},
			 sequence_name => $$store_option{'sequence_name'},
			 table_name    => $$store_option{'table_name'},
			);

			# Ensure a manager is available.

			if (! $$store_option{'manager'})
			{
				require CGI::Uploader::Store::Manager;

				$$store_option{'manager'} = CGI::Uploader::Store::Manager -> new();
			}

			# Call either the caller's manager or the default manager.

			$$meta_data{'id'}               = $$store_option{'manager'} -> process($field_name, $meta_data, %$store_option);
			$$meta_data{'server_file_name'} = $self -> save($$store_option{'path'}, $temp_file_name, $meta_data);

			if ($store_count == 1)
			{
				$$store_option{'manager'} -> save($$store_option{'table_name'}, $meta_data);
			}
		}

		File::Temp::cleanup();
	}

} # End of upload.

# -----------------------------------------------

sub validate_field_options
{
	my($self, $field_name) = (shift, shift);
	my($called)            = __PACKAGE__ . " with form field '$field_name'";

	validate_with
	(
	 called => $called,
	 params => \@_,
	 spec   =>
	 {
		 generate =>
		 {
			 optional => 1,
			 type     => UNDEF | ARRAYREF,
		 },
		 store =>
		 {
			 type => ARRAYREF,
		 },
	 },
	);

} # End of validate_field_options.

# -----------------------------------------------

sub validate_store_options
{
	my($self)  = shift @_;
	my(%param) = validate
	(
	 @_,
	 {
		 column_map =>
		 {
			 optional => 1,
			 type     => UNDEF | HASHREF,
		 },
		 dbh =>
		 {
			 callbacks =>
			 {
				 postgres => sub
				 {
					 my($result) = 1;

					 # If there is a dbh, is the database Postgres,
					 # and, if so, is the sequence_name provided?

					 if ($$_[0])
					 {
						 my($db_server) = $$_[0] -> get_info(17);

						 $result = ($db_server eq 'PostgreSQL') ? $$_[1]{'sequence_name'} : 1;
					 }

					 return $result;
				 },
			 },
			 optional  => 1,
		 },
		 dsn =>
		 {
			 optional => 1,
			 type     => UNDEF | ARRAYREF,
		 },
		 path =>
		 {
			 type => SCALAR,
		 },
		 sequence_name =>
		 {
			 optional => 1,
			 type     => UNDEF | SCALAR,
		 },
		 table_name =>
		 {
			 type => SCALAR,
		 },
	 },
	);

	# Must do this separately, because when undef is passed in,
	# Params::Validate does not honour the default clause :-(.

	$param{'column_map'} ||=
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

	return {%param};

} # End of validate_store_options.

# -----------------------------------------------

sub work
{
	my($self, $field_name, $temp_file_name) = @_;
	my($q)         = $self -> query();
	my($file_name) = $q -> param($field_name);

	my($fh);
	my($mime_type);

	if ($q -> isa('Apache::Request') || $q -> isa('Apache2::Request') )
	{
		my($upload) = $q -> upload($field_name);
		$fh         = $upload -> fh();
		$mime_type  = $upload -> type() || '';
	}
	else # It's a CGI.
	{
		$fh        = $q -> upload($field_name);
		$mime_type = $q -> uploadInfo($fh) || '';

		if ($mime_type)
		{
			$mime_type = $$mime_type{'Content-Type'} || '';
		}

		if (! $fh && $q -> cgi_error() )
		{
			confess $q -> cgi_error();
		}
	}

	if (! $fh)
	{
		confess 'Unable to generate a file handle';
	}

	binmode($fh);
	copy($fh, $temp_file_name) || confess "Unable to create temp file '$temp_file_name': $!";

	return
	{
		client_file_name => $file_name,
		date_stamp       => 'now()',
		extension        => '',
		height           => 0,
		mime_type        => $mime_type,
		parent_id        => 0,
		server_file_name => '',
		size             => (stat $temp_file_name)[7],
		width            => 0,
	};

} # End of work.

# -----------------------------------------------

1;

=pod

=head1 NAME

CGI::Uploader - Manage CGI uploads using an SQL database

=head1 Synopsis

	my($u) = CGI::Uploader -> new
	(
		query    => ..., # Optional.
		temp_dir => ..., # Optional.
	) -> upload # Mandatory.
	(
	form_field_1 => [...], # Mandatory. An arrayref of hashrefs.
	form_field_2 => [...], # Mandatory. Another arrayref of hashrefs.
	);

	$u -> generate # Optional.
	(
	form_field_1 => [...], # Mandatory. An arrayref of hashrefs.
	form_field_2 => [...], # Mandatory. Another arrayref of hashrefs.
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

Options:

=over 4

=item query => $q

Use this to pass in a query object.

This object is expected to belong to one of these classes:

=over 4

=item Apache::Request

=item Apache2::Request

=item CGI

=back

If not provided, an object of type C<CGI> will be created and used to do the uploading.

Warning: CGI::Simple cannot be supported. See this ticket, which is I<not> resolved:

http://rt.cpan.org/Ticket/Display.html?id=14838

There is a comment in the source code of CGI::Simple about this issue. Search for 14838.

This key is optional.

=item temp_dir => 'String'

Note the spelling of I<temp_dir>.

If not provided, an object of type C<File::Spec> will be created and its tmpdir() method called.

This key is optional.

=back

=head1 Method: upload(%hash)

You must pass a hash to C<upload(...)>.

The keys of this hash are CGI form field names (where the fields are of type I<file>).

C<CGI::Uploader> cycles thru these keys, using each one in turn to drive a single upload.

Each key points to an arrayref of options which specifies how to process the field.

Use multiple elements in the arrayref to store multiple sets of meta-data, all based on the same uploaded file.

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

This key is optional if you use the I<manager> key, since in that case you do anything in your own
storage manager code.

If you do provide the I<dbh> key, it is passed in to your manager just in case you need it.

Also, if you provide I<dbh>, the I<dsn> key, below, is ignored.

If you do not provide the I<dbh> key, the default manager uses the I<dsn> arrayref to create a
dbh via C<DBI>.

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

The default manager class calls DBI -> connect(@$dsn) to connect to the database, i.e. in order
to generate a I<dbh>, when you don't provide a I<dbh> key.

=item manager => $object

This is an instance of your class which will manage the transfer of meta-data to storage.

This key is optional.

In the case you provide the I<manager> key, your object is responsible for saving (or discarding!) the meta-data.

If you provide an object here, C<CGI::Uploader> will call
$object => process(meta_data => $meta_data, field_name => $field_name, %{...}).

Parameters are:

=over 4

=item $meta_data

I<$meta_data> will be a hashref of options generated by the uploading process

=item $field_name

I<$field_name> will be the 'current' CGI form field.

Remember, I<upload()> is iterating over all your CGI form field parameters at this point.

=item %{...}

%{...} will be the 'current' hashref, one of the arrayref elements passed to I<upload()>.

See the next section for the definition of the meta-data.

=back

If you do not provide the I<manager> key, C<CGI::Uploader> will create an instance of the default manager
C<CGI::Uploader::Store::Manager>, and use that.

=item sequence_name => 'String'

This is the name of the sequence used to generate values for the primary key of the table.

You would normally only need this when using Postgres.

This key is optional if you use the I<manager> key, since in that case you can do anything in your own
storage manager code. If you do provide the I<sequence_name> key, it is passed in to your manager
just in case you need it.

This key is mandatory if you use Postgres and do not use the I<manager> key, since without the I<manager> key
I<sequence_name> must be passed in to the default manager C<CGI::Uploader::Store::Manager>.

=item table_name => 'String'

This is the name of the table into which to store the meta-data.

This key is optional if you use the I<manager> key, since in that case you can do anything in your own
storage manager code. If you do provide the I<table_name> key, it is passed in to your manager
just in case you need it.

This key is mandatory if you do not use the I<manager> key, since without the I<manager> key
I<table_name> must be passed in to the default manager C<CGI::Uploader::Store::Manager>.

=back

=head1 The I<generate> key

The I<generate> key points to an arrayref of hashrefs.

Use multiple elements to store multiple versions of the uploaded file.

Each hashref contains the following keys:

=over 4

=item One rainy day, design this section of the code, and document it

=back

=head1 Sample Code

The simplest option, then, is to use

	CGI::Uploader->new()->upload(file_name => [{dbh => $dbh, table_name => 'uploads'}]);

and let C<CGI::Uploader> do all the work.

For Postgres, make that

	CGI::Uploader->new()->upload(file_name => [{dbh => $dbh, sequence_name => 'uploads_id_seq', table_name => 'uploads'}]);

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

V 3 was by Mark Stosberg and Ron Savage <ron@savage.net.au>.

Ron's home page: http://savage.net.au/index.html

=head1 Licence

Artistic.

=cut
