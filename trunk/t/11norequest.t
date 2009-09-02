use strict;
use warnings;
use Test::More tests => 4;

use FindBin;
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'TestApp' or die }

ok my $c  = TestApp->new, 'Instantiate app object';
ok my $tt = $c->view('TT'), 'Get TT view object';
is $tt->render($c, 'test.tt', { message => 'hello' }), 'hello',
    'render() should return the template output';
