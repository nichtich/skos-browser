use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use SKOS::Browser;

my $app = SKOS::Browser->new();

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/');
    is $res->code, 500, '/ no config' or diag $res->content;

    $app->load_config( 't/data/valid_config.json' );
    $res = $cb->(GET '/');
    is $res->code, 200, '/ valid config' or diag $res->content;

    $app->load_config( 't/data/missing_config.json' );
    $res = $cb->(GET '/');
    is $res->code, 500, '/ missing config' or diag $res->content;

    $app->load_config( 't/data/invalid_config.json' );
    is $res->code, 500, '/ missing config' or diag $res->content;

    $app->load_config( 't/data/invalid_store_config.json' );
    is $res->code, 500, '/ invalid store config' or diag $res->content;

    $app->load_config( 't/data/store_config.json' );
    $res = $cb->(GET '/');
    is $res->code, 200, '/ valid config' or diag $res->content;

    $app->load_config( 't/data/templates_config.json' );
    $res = $cb->(GET '/');
    is $res->code, 200, '/ template config' or diag $res->content;

    # TODO: test reload_config (modfied file) and templates
};

done_testing;
