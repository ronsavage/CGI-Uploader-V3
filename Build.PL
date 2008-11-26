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
) -> create_build_script();
