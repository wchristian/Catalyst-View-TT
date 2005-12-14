use strict;
use warnings;
use Test::More tests => 9;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');
my $response;

ok(($response = request("/test_includepath?view=Appconfig&template=testpath.tt&additionalpath=test_include_path"))->is_success, 'additional_template_path');
is($response->content, TestApp->config->{default_message}, 'message ok');

ok(($response = request("/test_includepath?view=Includepath&template=testpath.tt"))->is_success, 'scalar include path from config');
is($response->content, TestApp->config->{default_message}, 'message ok');

ok(($response = request("/test_includepath?view=Includepath2&template=testpath.tt"))->is_success, 'object ref (that stringifys to the path) include path from config');
is($response->content, TestApp->config->{default_message}, 'message ok');

ok(($response = request("/test_includepath?view=Includepath3&template=testpath.tt&addpath=test_include_path"))->is_success, 'array ref include path from config not replaced by another array');
is($response->content, TestApp->config->{default_message}, 'message ok');

