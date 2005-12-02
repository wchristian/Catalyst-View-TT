use strict;
use warnings;
use Test::More tests => 5;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');
my $response;

ok(($response = request("/test_includepath?view=Appconfig&template=testpath.tt&additionalpath=test_include_path"))->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'message ok');


ok(($response = request("/test_includepath?view=Includepath&template=testpath.tt"))->is_success, 'request ok');
is($response->content, TestApp->config->{default_message}, 'message ok');

