#!/usr/bin/env perl
use warnings;
use strict;

use Test::More tests => 2;
use Test::Deep;
use Module::Runtime qw( use_module );


subtest 'submit returns Declined by default' => sub {
    my $mock_client = new_ok( use_module('Business::OnlinePayment'), ['Mock'] );

    $mock_client->content(action => 'Credit', card_number => '4111111111111111');

    $mock_client->submit;

    is($mock_client->error_message, 'Declined') or diag explain $mock_client;
};

subtest 'submit throws error if no content is defined' => sub {
    my $mock_client = new_ok( use_module('Business::OnlinePayment'), ['Mock'] );

    $mock_client->content(undef => undef);

    eval { $mock_client->submit };

    like($@, qr/missing action/i, 'Throws error when action is missing');
};

subtest 'submit returns expected result when mock_response is defined' => sub {
    my $mock_client = new_ok( use_module('Business::OnlinePayment'), ['Mock'] );

    $mock_client->set_mock_response({
      4111111111111
    })

    $mock_client->content(action => 'Credit', card_number => '4111111111111111');

    my $result = $mock_client->submit;

    my $expected = {
        error_message => 'Declined',
        is_success    => 0,
        error_code    => 100,
        order_number  => ignore(),
    };

    cmp_deeply($result, $expected) or diag explain $result;
}
