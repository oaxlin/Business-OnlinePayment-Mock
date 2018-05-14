#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::Mock' );
}

diag( "Testing Business::OnlinePayment::Mock $Business::OnlinePayment::Mock::VERSION, Perl $], $^X" );
