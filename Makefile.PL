use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Mark Stosberg, Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Manage CGI uploads using an SQL database',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST CGI-Uploader-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'CGI-Uploader',
 NAME      => 'CGI::Uploader',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 File::Basename      => 0,
	 File::Copy          => 0,
	 File::Path          => 0,
	 File::Spec          => 0,
	 File::Temp          => 0,
	 HTML::Template      => 0,
	 HTTP::BrowserDetect => 0,
	 Image::Size         => 0,
	 MIME::Types         => 0,
	 Params::Validate    => 0,
	 Squirrel            => 0 # I.e. Mouse or Moose.
 },
 VERSION_FROM	=> 'lib/CGI/Uploader.pm',
);
