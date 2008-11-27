package CGI::Uploader::Config;

use strict;
use warnings;

use Carp;

use Config::IniFiles;

use Squirrel;

our $VERSION = '2.90_01';

# -----------------------------------------------

has config      => (is => 'rw', isa => 'Config::IniFiles');
has dsn         => (is => 'rw', isa => 'ArrayRef');
has form_action => (is => 'rw', isa => 'Str');
has table_name  => (is => 'rw', isa => 'Str');
has tmpl_path   => (is => 'rw', isa => 'Str');

# -----------------------------------------------

sub BUILD
{
	my($self)    = @_;
#	my($name)    = '.ht.cgi.uploader.conf';
#	my($path)    = $INC{'CGI/Uploader/Config.pm'};
#	$path        =~ s/Config.pm/$name/;
	my($path)    = '/home/ron/perl.modules/CGI-Up/lib/CGI/Uploader/.ht.cgi.uploader.conf';
	my($section) = 'global';

	# Check [global].

	$self -> config(Config::IniFiles -> new(-file => $path) );

	if (! $self -> config() -> SectionExists($section) )
	{
		Carp::croak "Config file '$path' does not contain the section [$section]";
	}

	# Check [x] where x is host=x within [global].

	$section = $self -> config() -> val($section, 'host');

	if (! $self -> config() -> SectionExists($section) )
	{
		Carp::croak "Config file '$path' does not contain the section [$section]";
	}

	$self -> dsn([map{$self -> config() -> val($section, $_)} (qw/dsn username password/)]);
	$self -> form_action($self -> config() -> val($section, 'form_action') );
	$self -> table_name($self -> config() -> val($section, 'table_name') );
	$self -> tmpl_path($self -> config() -> val($section, 'tmpl_path') );

}	# End of BUILD.

# --------------------------------------------------

1;
