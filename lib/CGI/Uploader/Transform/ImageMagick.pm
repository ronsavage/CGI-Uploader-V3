package CGI::Uploader::Transform::ImageMagick;

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
use Image::Magick;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Uploader::Transform::ImageMagick ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
transformer
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '2.90_02';

# -----------------------------------------------

sub calculate_dimensions
{
	my($image, $new_width, $new_height)   = @_;
	my($original_width, $original_height) = $image -> Get('width', 'height');

	if (! $new_width)
	{
		$new_width = sprintf("%.1d", ($original_width * $new_height) / $original_height);
	}

	if (! $new_height)
	{
		$new_height = sprintf("%.1d", ($original_height * $new_width) / $original_width);
	}

	return ($new_width, $new_height);

} # End of calculate_dimensions.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless({%arg}, $class);

	return $self;

}	# End of new.

# -----------------------------------------------

sub transformer
{
	my(%arg)   = @_;
	my($image) = Image::Magick -> new();

	return sub
	{
		my($old_name, $extension) = @_;
		my($result)     = $image -> Read($old_name);
		my(@dimensions) = calculate_dimensions($image, $arg{'width'}, $arg{'height'});
		$result         = $image -> Resize(sprintf '%i x %i', @dimensions);
		my($fh, $name)  = tempfile('CGIuploaderXXXXX', UNLINK => 1, DIR => File::Spec -> tmpdir() );
		$result         = $image -> Write($name);

		return ($name, $extension);
	};

} # End of transformer.

# -----------------------------------------------

1;
