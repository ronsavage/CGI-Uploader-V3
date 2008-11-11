use Module::Build;

Module::Build -> new
(
 module_name    => 'CGI::Up',
 license        => 'artistic',
 dist_abstract  => 'Manage CGI uploads using an SQL database',
 dist_author    => 'Mark Stosberg, Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0,
	 Test::Pod  => 0,
 },
 requires =>
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
) -> create_build_script();
