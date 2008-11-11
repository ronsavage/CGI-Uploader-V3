package CGI::Up::Config;

use strict;
use warnings;

use Carp;

use Config::IniFiles;

use Squirrel;

our $VERSION = '1.00';

# -----------------------------------------------

has config      => (is => 'rw', isa => 'Config::IniFiles');
has dsn         => (is => 'rw', isa => 'Str');
has form_action => (is => 'rw', isa => 'Str');
has password    => (is => 'rw', isa => 'Str');
has section     => (is => 'rw', isa => 'Str');
has table_name  => (is => 'rw', isa => 'Str');
has tmpl_path   => (is => 'rw', isa => 'Str');
has username    => (is => 'rw', isa => 'Str');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($name) = '.htcgiup.conf';
	my($path) = $INC{'CGI/Up/Config.pm'};
	$path     =~ s/Config.pm/$name/;

	# Check [global].

	$self -> config(Config::IniFiles -> new(-file => $path) );
	$self -> section('global');

	if (! $self -> config() -> SectionExists($self -> section() ) )
	{
		Carp::croak "Config file '$path' does not contain the section [" . $self -> section() . ']';
	}

	# Check [x] where x is host=x within [global].

	$self -> section($self -> config() -> val($self -> section(), 'host') );

	if (! $self -> config() -> SectionExists($self -> section() ) )
	{
		Carp::croak "Config file '$path' does not contain the section [" . $self -> section() . ']';
	}

	$self -> dsn($self -> config() -> val($self -> section(), 'dsn') );
	$self -> form_action($self -> config() -> val($self -> section(), 'form_action') );
	$self -> password($self -> config() -> val($self -> section(), 'password') );
	$self -> table_name($self -> config() -> val($self -> section(), 'table_name') );
	$self -> tmpl_path($self -> config() -> val($self -> section(), 'tmpl_path') );
	$self -> username($self -> config() -> val($self -> section(), 'username') );

}	# End of BUILD.

# --------------------------------------------------

1;
