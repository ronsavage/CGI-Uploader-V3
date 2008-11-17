package CGI::Up;

use strict;
use warnings;

use File::Basename;
use File::Copy; # For copy.
use File::Path;
use File::Spec;
use File::Temp 'tempfile';

use HTTP::BrowserDetect;

use MIME::Types;

use Params::Validate ':all';

use Squirrel;

our $VERSION = '2.90';

# -----------------------------------------------

has dbh      => (is => 'rw', required => 0, predicate => 'has_dbh', isa => 'Any');
has dsn      => (is => 'rw', required => 0, predicate => 'has_dsn', isa => 'Any');
has imager   => (is => 'rw', required => 0, isa => 'Any');
has manager  => (is => 'rw', required => 0, isa => 'Any');
has query    => (is => 'rw', required => 0, predicate => 'has_query', isa => 'Any');
has temp_dir => (is => 'rw', required => 0, predicate => 'has_temp_dir', isa => 'Any');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# See if the caller specifed a dsn but no dbh.

	if ($self -> has_dsn() && ! $self -> has_dbh() )
	{
		require DBI;

		$self -> dbh(DBI -> connect(@{$self -> dsn()}) );
	}

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

sub copy_temp_file
{
	my($self, $temp_file_name, $meta_data, $store_option) = @_;
	my($path) = $$store_option{'path'};
	$path     =~ s|^(.+)/$|$1|;

	if ($$store_option{'file_scheme'} eq 'md5')
	{
		require Digest::MD5;

		import Digest::MD5  qw/md5_hex/;

		my($md5) = md5_hex($$meta_data{'id'});
		$md5     =~ s|^(.)(.)(.).*|$1/$2/$3|;
		$path    = File::Spec -> catdir($path, $md5);
	}

	if (! -e $path)
	{
		File::Path::mkpath($path);
	}

	my($server_file_name) = File::Spec -> catdir($path, "$$meta_data{'id'}.png");

	copy($temp_file_name, $server_file_name);

	return $server_file_name;

} # End of copy_temp_file.

# -----------------------------------------------

sub do_insert
{
	my($self, $field_name, $meta_data, %store_option) = @_;

	# Use either the caller's dbh or fabricate one.

	if (! $self -> has_dbh() )
	{
		# CGI::Uploader checked that at least one of dbh and dsn was specified.
		# So, we don't need to test for dsn here.

		require DBI;

		$self -> dbh(DBI -> connect(@{$store_option{'dsn'} }) );
	}

	my($db_server) = $self -> dbh() -> get_info(17);
	my($sql)       = "insert into $store_option{'table_name'}";

	# Ensure, if the caller is using Postgres, and they want the id field populated,
	# that we stuff the next value from the callers' sequence into it.

	if ( ($db_server eq 'PostgreSQL') && $store_option{'column_map'}{'id'})
	{
		$$meta_data{'id'} = $self -> dbh() -> selectrow_array("select nextval('$store_option{'sequence_name'}')");
	}

	my(@bind);
	my(@column);
	my($key);

	for $key (keys %$meta_data)
	{
		push @column, $store_option{'column_map'}{$key};
		push @bind, $$meta_data{$key};
	}

	$sql .= '(' . join(', ', @column) . ') values (' . ('?, ' x $#bind) . '?)';

	my($sth) = $self -> dbh() -> prepare($sql);

	$sth -> execute(@bind);

	return $self -> dbh() -> last_insert_id(undef, undef, $store_option{'table_name'}, undef)

} # End of do_insert.

# -----------------------------------------------

sub do_update
{
	my($self, $meta_data, %store_option) = @_;
	my($sql) = "update $store_option{'table_name'} set server_file_name = ?, height = ?, width = ? where id = ?";
	my($sth) = $self -> dbh() -> prepare($sql);

	$sth -> execute($$meta_data{'server_file_name'}, $$meta_data{'height'}, $$meta_data{'width'}, $$meta_data{'id'});

} # End of do_update.

# -----------------------------------------------

sub do_upload
{
	my($self, $field_name, $temp_file_name) = @_;
	my($q)         = $self -> query();
	my($file_name) = $q -> param($field_name);

	# Now strip off the volume/path info, if any.

	my($client_os) = $^O;
	my($browser)   = HTTP::BrowserDetect -> new();
	$client_os     = 'MSWin32' if ($browser -> windows() );
	$client_os     = 'MacOS'   if ($browser -> mac() );
	$client_os     = 'Unix'    if ($browser->macosx() );

	File::Basename::fileparse_set_fstype($client_os);

	$file_name = File::Basename::fileparse($file_name,[]);

	my($fh);
	my($mime_type);

	if ($q -> isa('Apache::Request') || $q -> isa('Apache2::Request') )
	{
		my($upload) = $q -> upload($field_name);
		$fh         = $upload -> fh();
		$mime_type  = $upload -> type();
	}
	else # It's a CGI.
	{
		$fh        = $q -> upload($field_name);
		$mime_type = $q -> uploadInfo($fh);

		if ($mime_type)
		{
			$mime_type = $$mime_type{'Content-Type'};
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
		# If is a provided extension but no MIME::Type extension, use that.

		$server_ext = $client_ext;
	}

	return
	{
		client_file_name => $file_name,
		date_stamp       => 'now()',
		extension        => $server_ext,
		height           => 0,
		id               => 0,
		mime_type        => $mime_type || '',
		parent_id        => 0,
		server_file_name => '',
		size             => (stat $temp_file_name)[7],
		width            => 0,
	};

} # End of do_upload.

# -----------------------------------------------

sub get_size
{
	my($self, $meta_data) = @_;

	require Image::Size;

	my(@size) = Image::Size::imgsize($$meta_data{'server_file_name'});

	if (! defined $size[0])
	{
		$size[0] = 0;
		$size[1] = 0;
	}

	$$meta_data{'height'} = $size[0];
	$$meta_data{'width'}  = $size[1];

} # End of get_size.

# -----------------------------------------------

sub upload
{
	my($self, %field) = @_;

	# Loop over the CGI form fields.

	my($field_name, $field_option);
	my($id);
	my($meta_data, @meta_data);
	my($store, $store_option);

	for $field_name (sort keys %field)
	{
		$field_option = $field{$field_name};

		# Perform the upload for this field.

		my($temp_fh, $temp_file_name) = tempfile('CGIuploaderXXXXX', UNLINK => 1, DIR => $self -> temp_dir() );
		$meta_data                    = $self -> do_upload($field_name, $temp_file_name);
		my($store_count)              = 0;

		# Loop over all store options.

		for $store_option (@$field_option)
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
			 file_scheme   => $$store_option{'file_scheme'},
			 path          => $$store_option{'path'},
			 sequence_name => $$store_option{'sequence_name'},
			 table_name    => $$store_option{'table_name'},
			);

			# Ensure an imager is available.

			$self -> imager($$store_option{'imager'} ? $$store_option{'imager'} : $self);

			# Ensure a manager is available.

			$self -> manager($$store_option{'manager'} ? $$store_option{'manager'} : $self);

			# Call either the caller's manager or the default manager.

			$$meta_data{'id'}               = $self -> manager() -> do_insert($field_name, $meta_data, %$store_option);
			$$meta_data{'server_file_name'} = $self -> copy_temp_file($temp_file_name, $meta_data, $store_option);

			if ($store_count == 1)
			{
				$self -> imager() -> get_size($meta_data);
				$self -> manager() -> do_update($meta_data, %$store_option);
			}

			push @meta_data, {field => $field_name, id => $$meta_data{'id'} };
		}

		File::Temp::cleanup();
	}

	return \@meta_data;

} # End of upload.

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
		 file_scheme =>
		 {
			 optional => 1,
			 type     => UNDEF | SCALAR,
		 },
		 imager =>
		 {
			 optional => 1,
			 type     => UNDEF | SCALAR,
		 },
		 manager =>
		 {
			 optional => 1,
			 type     => UNDEF | SCALAR,
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

	$param{'file_scheme'} ||= 'simple';

	return {%param};

} # End of validate_store_options.

# -----------------------------------------------

1;

=pod

=head1 NAME

CGI::Uploader - Manage CGI uploads using an SQL database

=head1 Synopsis

	# Create an upload object.

	my($u) = CGI::Uploader -> new
	(
		dbh      => $dbh,  # Optional. Or specify in call to upload().
		dsn      => [...], # Optional. Or specify in call to upload().
		imager   => $obj,  # Optional. Or specify in call to upload().
		manager  => $obj,  # Optional. Or specify in call to upload().
		query    => $q,    # Optional.
		temp_dir => $t,    # Optional.
	);

	# Upload N files.

	$u -> upload # Mandatory.
	(
	form_field_1 => # An arrayref of hashrefs.
	[
	{ # First, mandatory, set of options for storing the uploaded file.
	column_map    => {...}, # Optional.
	dbh           => $dbh,  # Optional. But one of dbh or dsn is
	dsn           => [...], # Optional. mandatory if no manager.
	file_scheme   => $s,    # Optional.
	imager        => $obj,  # Optional.
	manager       => $obj,  # Optional. If present, all others params are optional.
	sequence_name => $s,    # Optional, but mandatory if Postgres and no manager.
	table_name    => $s,    # Optional if manager, but mandatory if no manager.
	},
	{ # Second, etc, optional sets of options for storing copies of the file.
	},
	],
	form_field_2 => [...], # Another arrayref of hashrefs.
	);

	# Generate N files from each uploaded file.

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

C<new()> returns a C<CGI::Uploader> object.

This is the class's contructor.

You must pass a hash to C<new()>.

Options:

=over 4

=item dbh => $dbh

This key may be specified globally or in the call to C<upload()>.

See below for an explanation, including how this key interacts with I<dsn>.

This key is optional.

=item dsn => $dsn

This key may be specified globally or in the call to C<upload()>.

See below for an explanation, including how this key interacts with I<dbh>.

This key is optional.

=item imager => $obj

This key may be specified globally or in the call to C<upload()>.

This key is optional.

=item manager => $obj

This key may be specified globally or in the call to C<upload()>.

This key is optional.

=item query => $q

Use this to pass in a query object.

This object is expected to belong to one of these classes:

=over 4

=item Apache::Request

=item Apache2::Request

=item CGI

=back

If not provided, an object of type C<CGI> will be created and used to do the uploading.

If you want to use a different type of object, just ensure it has these CGI-compatible methods:

=over 4

=item cgi_error()

This is only called if something goes wrong.

=item upload()

=item uploadInfo()


=back

I<Warning # 1>: CGI::Simple cannot be supported. See this ticket, which is I<not> resolved:

http://rt.cpan.org/Ticket/Display.html?id=14838

There is a comment in the source code of CGI::Simple about this issue. Search for 14838.

I<Warning # 2>: When using the Apache modules, you can only read the CGI form field values once.

That is, calling $q -> param($field_name) will only return a meaningful value on the first call,
for a given value of $field_name. This is part of mod_perl's design.

This key is optional.

=item temp_dir => 'String'

Note the spelling of I<temp_dir>.

If not provided, an object of type C<File::Spec> will be created and its tmpdir() method called.

This key is optional.

=back

=head1 Method: upload(%hash)

You must pass a hash to C<upload()>.

The keys of this hash are CGI form field names (where the fields are of type I<file>).

C<CGI::Uploader> cycles thru these keys, using each one in turn to drive a single upload.

Note: C<upload()> returns an arrayref of hashrefs, one for each uploaded file stored.

The structure of these hashrefs is:

=over 4

=item I<field> => CGI form field name

=item I<id>    => The value of the id column in the database

=back

You can use this data, e.g., to read the meta-data from the database and populate form fields to
inform the user of the results of the upload.

=head2 Processing Steps

A mini-synopsis:

	$u -> upload
	(
	file_name_1 =>
	[
	{First set of storage options for this file},
	{Second set of storage options},
	{...},
	],
	);

=over 4

=item Upload file

C<upload()> calls C<do_upload()> to do the work of uploading the caller's file to a temporary file,
and C<do_upload()> returns a hashref of meta-data associated with the file.

This is done once, whereas the following 3 steps are done once for each hashref of storage options
you specify in the arrayref pointed to by the 'current' CGI form field's name.

=item Save the meta-data

C<upload()> calls the C<do_insert()> method on the manager object to save the meta-data.

C<insert()> returns the I<last insert id> from that insert. This id is used later when the temporary
file is copied to a permanent file.

=item Create the permanent file

C<upload()> calls C<copy_temp_file()> to save the file permanently.

=item Determine the height and width of images

C<upload()> calls the C<get_size()> method on the imager object to get the image size.

=item Update the meta-data with the permanent file's name and image size

C<upload()> calls the C<do_update()> method on the manager object to put the permanent file's name
into the database record, along with the height and width.

=back

=head2 Details

Each key in the hash passed in to C<upload()> points to an arrayref of options which specifies how to process the
form field.

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

More detail is provided below, under I<Meta-data>.

=item dbh => $dbh

This is a database handle for use by the default manager class (which is just C<CGI::Uploader>)
discussed below, under I<manager>.

This key is optional if you use the I<manager> key, since in that case you do anything in your own
storage manager code.

If you do provide the I<dbh> key, it is passed in to your manager just in case you need it.

Also, if you provide I<dbh>, the I<dsn> key, below, is ignored.

If you do not provide the I<dbh> key, the default manager uses the I<dsn> arrayref to create a
dbh via C<DBI>.

=item dsn => [...]

This key is optional if you use the I<manager> key, since in that case you do anything in your own
storage manager code.

If you do provide the I<dsn> key, it is passed in to your manager just in case you need it.

Using the default I<manager>, this key is ignored if you provide a I<dbh> key, but it is mandatory
when you do not provide a I<dbh> key.

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

=item file_scheme => 'String'

I<File_scheme> controls how files are stored on the web server's file system.

All files are stored in the directory specified by the I<path> option.

Each file name has the appropriate extension appended.

The possible values of I<file_scheme> are:

=over 4

=item md5

The file name is determined like this:

=over 4

=item Digest::MD5

Use the (primary key) I<id> returned by storing the meta-data in the database to seed
the Digest::MD5 module.

=item Create 3 subdirectories

Use the first 3 digits of the hex digest of the id to generate 3 levels of sub-directories.

=item Add the name

The file name is the (primary key) I<id> returned by storing the meta-data in the database.

=back

=item simple

The file name is the (primary key) I<id> returned by storing the meta-data in the database.

This is the default.

=back

=item imager => $object

This is an instance of your class which will determine the height and width of an image.

This key is optional.

If you provide an object here, C<CGI::Uploader> will call $object => get_size($meta_data).

You object uses $$meta_data{'server_file_name'} as the file's name, and returns the height and width in
$$meta_data{'height'} and $$meta_data{'width'}, respectively.

If you do not supply an I<imager> key, C<CGI::Uploader> requires Image::Size and calls its I<imgsize> function.

=item manager => $object

This is an instance of your class which will manage the transfer of meta-data to storage.

This key is optional.

In the case you provide the I<manager> key, your object is responsible for saving (or discarding!) the meta-data.

If you provide an object here, C<CGI::Uploader> will call
$object => do_insert(meta_data => $meta_data, field_name => $field_name, %{...}).

Parameters are:

=over 4

=item $meta_data

I<$meta_data> will be a hashref of options generated by the uploading process

See above, under I<column_map>, for the definition of the meta-data. Further details are below,
under I<Meta-data>.

=item $field_name

I<$field_name> will be the 'current' CGI form field.

Remember, I<upload()> is iterating over all your CGI form field parameters at this point.

=item %{...}

%{...} will be the 'current' hashref, one of the arrayref elements associated with the 'current' form field.

=back

If you do not provide the I<manager> key, C<CGI::Uploader> will do the work itself.

=item path => 'String'

This is a path on the web server's file system where a permanent copy of the uploaded file will be saved.

This key is mandatory.

=item sequence_name => 'String'

This is the name of the sequence used to generate values for the primary key of the table.

You would normally only need this when using Postgres.

This key is optional if you use the I<manager> key, since in that case you can do anything in your own
storage manager code. If you do provide the I<sequence_name> key, it is passed in to your manager
just in case you need it.

This key is mandatory if you use Postgres and do not use the I<manager> key, since without the I<manager> key,
I<sequence_name> must be passed in to the default manager (C<CGI::Uploader>).

=item table_name => 'String'

This is the name of the table into which to store the meta-data.

This key is optional if you use the I<manager> key, since in that case you can do anything in your own
storage manager code. If you do provide the I<table_name> key, it is passed in to your manager
just in case you need it.

This key is mandatory if you do not use the I<manager> key, since without the I<manager> key,
I<table_name> must be passed in to the default manager (C<CGI::Uploader>).

=back

=head1 Sample Code

The simplest option, then, is to use

	CGI::Uploader->new()->upload(file_name => [{dbh => $dbh, table_name => 'uploads'}]);

and let C<CGI::Uploader> do all the work.

For Postgres, make that

	CGI::Uploader->new()->upload(file_name => [{dbh => $dbh, sequence_name => 'uploads_id_seq', table_name => 'uploads'}]);

=head1 The I<generate> key

The I<generate> key points to an arrayref of hashrefs.

Use multiple elements to store multiple versions of the uploaded file.

Each hashref contains the following keys:

=over 4

=item One rainy day, design this section of the code, and document it

=back

=head1 Meta-data

More details of the meta-data can be found above, under I<column_map>.

Meta-data is a hashref, with these keys:

=over 4

=item client_file_name

This is the value submitted by the user for the 'current' CGI form field.

=item date_stamp

This value is the string 'now()', until the meta-data is saved in the database.

=item extension

This value is '' (the empty string), until the uploaded file is copied to a permanent file.

=item height

This value is 0 until the I<imager> object is called to process the permanent file.

=item id

This value is 0 until the meta-data is saved in the database.

=item mime_type

This value is the mime type returned by the query object, or '' (the empty string).

=item parent_id

This value is 0.

=item server_file_name

This value is '' (the empty string), until the uploaded file is copied to a permanent file.

=item size

This is the size in bytes of the uploaded file.

=item width

This value is 0 until the I<imager> object is called to process the permanent file.

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
