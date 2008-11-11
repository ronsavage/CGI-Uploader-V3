package CGI::Up::Test;

use CGI::Simple;
use CGI::Up;
use CGI::Up::Config;
use CGI::Uploader;
use DBIx::Admin::CreateTable;
use DBIx::Simple;
use HTML::Template;
use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has config     => (is => 'rw', isa => 'CGI::Up::Config');
has creator    => (is => 'rw', isa => 'DBIx::Admin::CreateTable');
has form       => (is => 'rw', isa => 'HTML::Template');
has q          => (is => 'rw', isa => 'CGI::Simple');
has simple     => (is => 'rw', isa => 'DBIx::Simple');
has table_name => (is => 'rw', isa => 'Str');
has web_page   => (is => 'rw', isa => 'HTML::Template');

# -----------------------------------------------

sub BUILD
{
	my($self)                     = @_;
	$CGI::Simple::DISABLE_UPLOADS = 0;

	$self -> config($config);

	my($tmpl_path) = $config -> tmpl_path();

	$self -> q(CGI::Simple -> new() );
	$self -> table_name($self -> config() -> table_name() );
	$self -> web_page(HTML::Template -> new(filename => 'web.page.tmpl', path => $tmpl_path) );
	$self -> form(HTML::Template -> new(filename => 'form.tmpl', path => $tmpl_path) );
	$self -> simple(DBIx::Simple -> connect($self -> config() -> dsn(), $self -> config() -> username(), $self -> config() -> password() ) );
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
extension        varchar(255),
height integer,
mime_type        varchar(255),
parent_id integer,
server_file_name varchar(255),
size integer,
width integer
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

sub use_cgi_simple
{
	my($self)   = @_;
	my($script) = 'use.cgi.simple.pl';

	$self -> form() -> param(form_action => $self -> config() -> form_action() . '/' . $script);
	$self -> web_page() -> param(name    => "$script and CGI::Simple V " . $CGI::Simple::VERSION);

	# Handle 1 or 2 files uploaded. See form.tmpl for details.

	my($i);
	my($field_name);
	my($original_file_name, $ok);
	my($uploaded_file_name);

	for $i (1 .. 2)
	{
		$field_name         = "file_name_$i";
		$original_file_name = $self -> q() -> param($field_name);

		if (! $original_file_name)
		{
			next;
		}

		$uploaded_file_name = "/tmp/uploaded_file_$i";
		$ok                 = $self -> q() -> upload($original_file_name, $uploaded_file_name);

		if ($ok)
		{
			$self -> form() -> param("original_file_name_$i" => $original_file_name);
			$self -> form() -> param("uploaded_file_name_$i" => $uploaded_file_name);
			$self -> form() -> param("size_$i"               => $self -> q() -> upload_info($original_file_name, 'size') );
			$self -> form() -> param("mime_type_$i"          => $self -> q() -> upload_info($original_file_name, 'mime') );
		}
		else
		{
			$self -> form() -> param("file_name_$i" => $self -> q() -> cgi_error() );
		}
	}

	$self -> web_page() -> param(content => $self -> form() -> output() );

	print $self -> q() -> header(), $self -> web_page() -> output();

} # End of run.

# -----------------------------------------------

sub use_cgi_uploader
{
	my($self) = @_;
	my($script) = 'use.cgi.uploader.pl';

	$self -> form() -> param(form_action => $self -> config() -> form_action() . '/' . $script);
	$self -> web_page() -> param(name    => "$script and CGI::Up V " . $CGI::Up::VERSION);

	# Handle 1 or 2 files uploaded. See form.tmpl for details.

	my($file_list) = {};

	my($i);
	my($field_name);
	my($original_file_name);

	for $i (1 .. 2)
	{
		$field_name         = "file_name_$i";
		$original_file_name = $self -> q() -> param($field_name);

		if (! $original_file_name)
		{
			next;
		}

		warn "File: $field_name => $original_file_name";

		$$file_list{$field_name} = {};
	}

	if (keys %$file_list)
	{
		my($u) = CGI::Uploader -> new
		(
		 dbh          => $self -> simple() -> dbh(),
		 file_scheme  => 'simple',
		 query        => $self -> q(),
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
		my(%var)    = $self -> q() -> Vars();
		my($result) = $u -> store_uploads(\%var);

#		warn "Result: $_ => $$result{$_}" for sort keys %$result;
#		warn '-' x 50;
	}

	$self -> web_page() -> param(content => $self -> form() -> output() );

	print $self -> q() -> header(), $self -> web_page() -> output();

} # End of use_cgi_uploader.

# -----------------------------------------------

1;
