package CGI::Up::Store::Manager;

use strict;
use warnings;

use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has column_map    => (is => 'rw', required => 1, isa => 'HashRef');
has dbh           => (is => 'rw', required => 0, isa => 'Any');
has dsn           => (is => 'rw', required => 0, predicate => 'has_dsn', isa => 'ArrayRef');
has meta_data     => (is => 'rw', required => 1, isa => 'HashRef');
has simple        => (is => 'rw', required => 0, isa => 'DBIx::Simple');
has sequence_name => (is => 'rw', required => 1, isa => 'Any');
has table_name    => (is => 'rw', required => 1, isa => 'Any');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	# Use either the caller's dbh or fabricate one.

	if ($self -> has_dbh() )
	{
		$self -> use_users_dbh();
	}
	else
	{
		# CGI::Uploader checked that at least one of dbh and dsn was specified.
		# So, we don't need to call $self -> has_dsn() here.

		require DBIx::Simple;

		$self -> simple(DBIx::Simple -> new(@{$self -> dsn()}) );
		$self -> dbh($self -> simple() -> dbh() );
		$self -> use_dbix_simple();
	}

}	# End of BUILD.

# -----------------------------------------------

sub use_dbix_simple
{
	my($self)       = @_;
	my($column_map) = $self -> column_map();
	my($db_server)  = $self -> dbh() -> get_info(17);
	my($meta_data)  = $self -> meta_data();
	my($sql)        = 'insert into ' . $self -> table_name();

	# Ensure, if the caller is using Postgres, and they want the id field populated,
	# that we stuff the next value from thec callers' sequence into it.

	if ($db_server eq 'PostgreSQL')
	{
		if ($$column_map{'id'})
		{
			$$meta_data{$$column_map{'id'} } = $self -> dbh() -> selectrow_array("select nextval('" . $self -> sequence_name() . "')");
		}
	}

	$self -> simple() -> iquery($sql, $meta_data);

} # End of use_dbix_simple.

# -----------------------------------------------

sub use_users_dbh
{
	my($self) = @_;

} # End of use_users_dbh.

# -----------------------------------------------

1;

=pod

=head1 NAME

CGI::Uploader::Store::Manager - Manage CGI uploads using an SQL database

=head1 Synopsis

You don't use this class - C<CGI::Uploader> does.

=head1 Description

C<CGI::Uploader::Store::Manager> is a pure Perl module.

=head1 Constructor and initialization

C<new(...)> returns a C<CGI::Uploader> object.

This is the class's contructor.

You pass a hash to <new()>.

Options:

=over 4

=item dbh => $dbh or ''

This is the I<dbh> passed in by C<CGI::Uploader>.

This key is mandatory.

=item meta_data => {}

This is the I<meta-data> passed in by C<CGI::Uploader>.

See the docs for C<CGI::Uploader> for details.

This key is mandatory.

=item sequence_name => 'String' or ''

This is the I<sequence_name> passed in by C<CGI::Uploader>.

This key is mandatory.

=item table_name => 'String'

This is the I<table_name> passed in by C<CGI::Uploader>.

This key is mandatory.

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
