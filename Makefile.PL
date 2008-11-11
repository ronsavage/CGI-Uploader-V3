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
	 FILES => 'blib/* Makefile MANIFEST CGI-Up-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'CGI-Up',
 NAME      => 'CGI::Up',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 Apache::DBI              => 0,
	 Apache2::Const           => 0,
	 Apache2::Request         => 0,
	 Apache2::RequestIO       => 0,
	 Apache2::RequestRec      => 0,
	 Apache2::RequestUtil     => 0,
	 Apache2::Response        => 0,
	 Apache2::Upload          => 0,
	 Carp                     => 0,
	 CGI::Simple              => 0,
	 Config::IniFiles         => 0,
	 DBD::Pg                  => 0,
	 DBI                      => 0,
	 DBIx::Admin::CreateTable => 0,
	 DBIx::Simple             => 0,
	 HTML::Template           => 0,
 },
 VERSION_FROM	=> 'lib/CGI/Up.pm',
);
