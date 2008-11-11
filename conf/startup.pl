# /home/ron/httpd/prefork/conf/startup.pl

use Apache2::Const;
use Apache2::Request;
use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Upload;

use Carp;

use CGI::Simple;
use CGI::Up;
use CGI::Up::Dispatcher;
use CGI::Up::Test;
use CGI::Uploader;

use Config::IniFiles;

use DBD::Pg;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;

use HTML::Template;

use Mouse;
use Squirrel;

# Must come last.
# Must use 'PerlOptions  +GlobalRequest' in httpd.conf.

use Apache::DBI;

1;

