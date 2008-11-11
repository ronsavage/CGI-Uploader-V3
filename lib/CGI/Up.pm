package CGI::Up;

use strict;
use warnings;

use Squirrel;

our $VERSION = '3.00';

# -----------------------------------------------

has hope => (is => 'rw', isa => 'Str');

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> hope('No');

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

=cut
