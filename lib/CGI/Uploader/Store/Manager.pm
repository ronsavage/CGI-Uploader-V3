package CGI::Uploader::Store::Manager;

use strict;
use warnings;

use Squirrel;

our $VERSION = '2.90';

# -----------------------------------------------

has column_map    => (is => 'rw', required => 1, isa => 'HashRef');
has dbh           => (is => 'rw', required => 0, isa => 'Any');
has dsn           => (is => 'rw', required => 0, isa => 'ArrayRef');
has field_name    => (is => 'rw', required => 1, isa => 'Str');
has meta_data     => (is => 'rw', required => 1, isa => 'HashRef');
has sequence_name => (is => 'rw', required => 0, isa => 'Any');
has table_name    => (is => 'rw', required => 1, isa => 'Any');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	my($meta_data) = $self -> meta_data();

	warn "meta_data: $_ => $$meta_data{$_}" for sort keys %$meta_data;

}	# End of BUILD.

# -----------------------------------------------

sub process
{
	my($self) = @_;
	my($dbh)  = $self -> dbh();

	# Use either the caller's dbh or fabricate one.

	if (! $dbh)
	{
		# CGI::Uploader checked that at least one of dbh and dsn was specified.
		# So, we don't need to call $self -> has_dsn() here.

		require DBI;

		$dbh = DBI -> connect(@{$self -> dsn()});
	}

	my($column_map) = $self -> column_map();
	my($db_server)  = $dbh -> get_info(17);
	my($meta_data)  = $self -> meta_data();
	my($sql)        = 'insert into ' . $self -> table_name();

	# Ensure, if the caller is using Postgres, and they want the id field populated,
	# that we stuff the next value from the callers' sequence into it.

	if ( ($db_server eq 'PostgreSQL') && ($$column_map{'id'}) )
	{
		$$meta_data{$$column_map{'id'} } = $dbh -> selectrow_array("select nextval('" . $self -> sequence_name() . "')");
	}

	my(@bind);
	my(@column);
	my($key);

	for $key (keys %$meta_data)
	{
		push @column, $key;
		push @bind, $$meta_data{$key};
	}

	$sql .= '(' . join(', ', @column) . ') values (' . ('?, ' x $#bind) . '?)';

	warn "SQL: $sql";

	my($sth) = $dbh -> prepare($sql);

	$sth -> execute(@bind);

} # End of process.

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
