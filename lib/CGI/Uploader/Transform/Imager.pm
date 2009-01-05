package CGI::Uploader::Transform::Imager;

# Author:
#	Ron Savage <ron@savage.net.au>
#
# Note:
#	\t = 4 spaces || die.

use strict;
use warnings;

require 5.005_62;

require Exporter;

use File::Temp 'tempfile';
use Imager;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Uploader::Transform::Imager ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '2.90_03';

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless({%arg}, $class);

	return $self;

}	# End of new.

# -----------------------------------------------

sub transform
{
	my(%arg)   = @_;
	my($image) = Imager -> new();

	return sub
	{
		my($old_name, $extension) = @_;
		my($result)    = $image -> read(file => $old_name, type => $extension);
		my($new_image) = $image -> scale(%arg);
		my($fh, $name) = tempfile('CGIuploaderXXXXX', UNLINK => 1, DIR => File::Spec -> tmpdir() );
		$result        = $new_image -> write(file => $name, type => $extension);

		return ($name, $extension);
	};

} # End of transform.

# -----------------------------------------------

1;
