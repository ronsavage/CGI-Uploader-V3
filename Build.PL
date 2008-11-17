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
	 Carp                     => 0,
	 CGI::Simple              => 0,
	 Config::IniFiles         => 0,
	 DBD::Pg                  => 0,
	 DBI                      => 0,
	 DBIx::Admin::CreateTable => 0,
	 File::Basename           => 0,
	 File::Copy               => 0,
	 File::Path               => 0,
	 File::Spec               => 0,
	 File::Temp               => 0,
	 HTML::Template           => 0,
	 HTTP::BrowserDetect      => 0,
	 MIME::Types              => 0,
 },
) -> create_build_script();
