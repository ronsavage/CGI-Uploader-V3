package CGI::Up::Test;

use CGI::Up::Config;
use DBIx::Admin::CreateTable;
use DBIx::Simple;
use File::Copy; # For copy.
use HTML::Template;
use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has config     => (is => 'rw', required => 0, isa => 'CGI::Up::Config');
has creator    => (is => 'rw', required => 0, isa => 'DBIx::Admin::CreateTable');
has form       => (is => 'rw', required => 0, isa => 'HTML::Template');
has simple     => (is => 'rw', required => 0, isa => 'DBIx::Simple');
has table_name => (is => 'rw', required => 0, isa => 'Str');
has web_page   => (is => 'rw', required => 0, isa => 'HTML::Template');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> config(CGI::Up::Config -> new() );

	my($tmpl_path) = $self -> config() -> tmpl_path();

	$self -> table_name($self -> config() -> table_name() );
	$self -> web_page(HTML::Template -> new(filename => 'web.page.tmpl', path => $tmpl_path) );
	$self -> form(HTML::Template -> new(filename => 'form.tmpl', path => $tmpl_path) );
	$self -> simple(DBIx::Simple -> connect(@{$self -> config() -> dsn()}) );
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> simple() -> dbh(), verbose => 0) );

} # End of BUILD.

# -----------------------------------------------

sub create_table
{
	my($self)        = @_;
	my($table_name)  = $self -> table_name();
	my($primary_key) = $self -> creator() -> generate_primary_key_sql($table_name);

	$self -> creator() -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
client_file_name varchar(255) not null,
date_stamp timestamp,
extension varchar(255) not null,
height integer not null,
mime_type varchar(255) not null,
parent_id integer not null,
server_file_name varchar(255), # Nullable because CGI::Uploader doesn't populate it.
size integer not null,
width integer not null
)
SQL

} # End of create_table.

# -----------------------------------------------

sub drop_table
{
	my($self) = @_;

	$self -> creator() -> drop_table($self -> table_name() );

} # End of drop_table.

# -----------------------------------------------

sub use_cgi
{
	my($self)   = @_;
	my($script) = 'use.cgi.pl';

	require CGI;

	my($q) = CGI -> new();

	# Handle 1 or 2 files uploaded. See form.tmpl for details.

	my($i);
	my($field_name, $fh);
	my($info);
	my($mime_type);
	my($original_file_name);
	my($size);
	my($uploaded_file_name);

	for $i (1 .. 2)
	{
		$field_name         = "file_name_$i";
		$original_file_name = $q -> param($field_name);

		if (! $original_file_name)
		{
			next;
		}

		# Upload one file.

		$uploaded_file_name = "/tmp/uploaded_file_$i";
		$fh                 = $q -> upload($field_name);

		if ($fh)
		{
			binmode $fh;
			copy($fh, $uploaded_file_name);

			$info      = $q -> uploadInfo($original_file_name) || {'Content-Type' => ''};
			$mime_type = $$info{'Content-Type'};
			$size      = -s $uploaded_file_name;

			$self -> form() -> param("original_file_name_$i" => $original_file_name);
			$self -> form() -> param("uploaded_file_name_$i" => $uploaded_file_name);
			$self -> form() -> param("size_$i"               => $size);
			$self -> form() -> param("mime_type_$i"          => $mime_type);
		}
		else
		{
			$self -> form() -> param(error => $q -> cgi_error() );
		}
	}

	$self -> form() -> param(form_action => $self -> config() -> form_action() . '/' . $script);
	$self -> web_page() -> param(name    => 'CGI V ' . $CGI::VERSION);
	$self -> web_page() -> param(content => $self -> form() -> output() );

	print $q -> header(), $self -> web_page() -> output();

} # End of use_cgi.

# -----------------------------------------------

sub use_cgi_simple
{
	my($self)   = @_;
	my($script) = 'use.cgi.simple.pl';

	require CGI::Simple;

	$CGI::Simple::DISABLE_UPLOADS = 0;
	my($q)                        = CGI::Simple -> new();

	warn 'Submitted params:';
	warn "$_ => " . $q -> param($_) for $q -> param();
	warn '-' x 50;

	# Handle 1 or 2 files uploaded. See form.tmpl for details.

	my($i);
	my($field_name);
	my($original_file_name, $ok);
	my($uploaded_file_name);

	for $i (1 .. 2)
	{
		$field_name         = "file_name_$i";
		$original_file_name = $q -> param($field_name);

		warn "CGI::Simple. $field_name => $original_file_name";

		if (! $original_file_name)
		{
			next;
		}

		# Upload one file.

		$uploaded_file_name = "/tmp/uploaded_file_$i";
		$ok                 = $q -> upload($original_file_name, $uploaded_file_name);

		if ($ok)
		{
			$self -> form() -> param("original_file_name_$i" => $original_file_name);
			$self -> form() -> param("uploaded_file_name_$i" => $uploaded_file_name);
			$self -> form() -> param("size_$i"               => $q -> upload_info($original_file_name, 'size') );
			$self -> form() -> param("mime_type_$i"          => $q -> upload_info($original_file_name, 'mime') );
		}
		else
		{
			$self -> form() -> param(error => $q -> cgi_error() );
		}
	}

	$self -> form() -> param(form_action => $self -> config() -> form_action() . '/' . $script);
	$self -> web_page() -> param(name    => 'CGI::Simple V ' . $CGI::Simple::VERSION);
	$self -> web_page() -> param(content => $self -> form() -> output() );

	print $q -> header(), $self -> web_page() -> output();

} # End of use_cgi_simple.

# -----------------------------------------------

sub use_cgi_uploader_v2
{
	my($self)   = @_;
	my($script) = 'use.cgi.uploader.v2.pl';

	require CGI;
	require CGI::Uploader;

	my($q) = CGI -> new();

	# Handle 1 or 2 files uploaded. See form.tmpl for details.

	my($file_list) = {};

	my($i);
	my($field_name);
	my($original_file_name);

	for $i (1 .. 2)
	{
		$field_name         = "file_name_$i";
		$original_file_name = $q -> param($field_name);

		if (! $original_file_name)
		{
			next;
		}

		$$file_list{$field_name} = {};
	}

	if (keys %$file_list)
	{
		# Upload all files.

		my($u) = CGI::Uploader -> new
		(
		 dbh          => $self -> simple() -> dbh(),
		 file_scheme  => 'simple',
		 query        => $q,
		 spec         => $file_list,
		 up_seq       => 'uploads_id_seq',
		 up_table     => $self -> table_name(),
		 updir_url    => 'http://127.0.0.1/uploads',
		 updir_path   => '/tmp',
		 up_table_map =>
		 {
			 bytes            => 'size',
			 extension        => 'extension',
			 file_name        => 'client_file_name',
			 gen_from_id      => 'parent_id',
			 height           => 'height',
			 mime_type        => 'mime_type',
			 upload_id        => 'id',
			 width            => 'width',
		 },
		);
		my($result) = $u -> store_uploads({$q -> Vars()});

		$self -> form() -> param(error => $q -> cgi_error() );

		# Retrieve data for each uploaded file.

		my($table_name) = $self -> table_name();

		my($id);
		my($meta_data);
		my($sql);

		for $i (1 .. 2)
		{
			$field_name = "file_name_$i";
			$id         = $$result{"${field_name}_id"} || 0;

			if ($id == 0)
			{
				next;
			}

			$sql       = "select * from $table_name where id = $id";
			$meta_data = $self -> simple() -> dbh() -> selectrow_hashref($sql);

			$self -> form() -> param("original_file_name_$i" => $$meta_data{'client_file_name'});
			$self -> form() -> param("uploaded_file_name_$i" => $$meta_data{'server_file_name'});
			$self -> form() -> param("size_$i"               => $$meta_data{'size'});
			$self -> form() -> param("mime_type_$i"          => $$meta_data{'mime_type'});
		}
	}

	$self -> form() -> param(form_action => $self -> config() -> form_action() . '/' . $script);
	$self -> web_page() -> param(name    => 'CGI::Uploader V ' . $CGI::Uploader::VERSION);
	$self -> web_page() -> param(content => $self -> form() -> output() );

	print $q -> header(), $self -> web_page() -> output();

} # End of use_cgi_uploader_v2.

# -----------------------------------------------

sub use_cgi_uploader_v3
{
	my($self)   = @_;
	my($script) = 'use.cgi.uploader.v3.pl';

	require CGI;
	require CGI::Up;

	my($q) = CGI -> new();

	if ($q -> param('file_name_1') )
	{
		CGI::Up -> new(query => $q) -> upload
			(
			 file_name_1 =>
			 {
				 store =>
				 [{
					 dsn           => $self -> config() -> dsn(),
					 path          => '/tmp',
					 sequence_name => 'uploads_id_seq',
					 table_name    => 'uploads',
				 }],
			 },
			);
	}

	$self -> form() -> param(form_action => $self -> config() -> form_action() . '/' . $script);
	$self -> web_page() -> param(name    => 'CGI::Uploader V ' . $CGI::Up::VERSION);
	$self -> web_page() -> param(content => $self -> form() -> output() );

	print $q -> header(), $self -> web_page() -> output();

} # End of use_cgi_uploader_v3.

# -----------------------------------------------

1;
