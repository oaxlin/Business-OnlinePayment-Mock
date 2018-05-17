package Business::OnlinePayment::Mock;
use strict;
use warnings;

=head1 NAME

Business::OnlinePayment::Mock - A backend for mocking fake results in the Business::OnlinePayment environment

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

=cut

use Business::OnlinePayment;
use Business::OnlinePayment::HTTPS;
use parent qw(Business::OnlinePayment::HTTPS);
our $me      = 'Business::OnlinePayment::Mock';

# VERSION
# PODNAME: Business::OnlinePayment::Mock
# ABSTRACT: A backend for mocking fake results for test cards

our $mock_responses;

our $default_mock = {
    error_message => 'Declined',
    is_success    => 0,
    error_code    => 100,
    order_number  => sub { time },
};

sub _info {
    return {
        info_compat       => '0.01',
        gateway_name      => 'Mock',
        gateway_url       => 'http://www.example.com',
        module_version    => $VERSION,
        supported_types   => ['CC'],
        supported_actions => {
            CC => [
                # 'Tokenize', # TODO
                'Normal Authorization',
                'Post Authorization',
                'Authorization Only',
                'Credit',
                'Void',
                'Auth Reversal',
            ],
        },
    };
}

=method set_default_mock

Sets the default mock for the Business::OnlinePayment object

   $mock->set_default_mock({
     error_message => 'Declined',
     is_success    => 0,
     error_code    => 100,
     order_number  => 1,
   });

=cut

sub set_default_mock {
    my ($self, $default) = @_;

    $default_mock = $default;
}

=method set_mock_response

Sets the mock response the Business::OnlinePayment object

   $mock->set_mock_response({
     error_message => 'Approved',
     is_success    => 1,
     error_code    => 0,
     order_number  => 1,
   });

=cut

sub set_mock_response {
    my ($self, $response, $set_as_default) = @_;

    $mock_responses->{delete $response->{'action'}}->{delete $response->{'card_number'}} = $response;

    $self->set_as_default($response) if $set_as_default;
}

=method test_transaction

Get/set the server used for processing transactions.  Because we are mocked, this method effectively does nothing.
Default: Live

  #Live
  $self->test_transaction(0);

  #Certification
  $self->test_transaction(1);

=cut

sub test_transaction {
    my $self = shift;

    $self->{'test_transaction'} = 1;
    $self->server('example.com');
    $self->port(443);
    $self->path('/example.html');

    return $self->{'test_transaction'};
}

=method submit

Submit the content to the mocked API

  $self->content(action => 'Credit' ...)

  $self->submit;

=cut

sub submit {
    my $self = shift;
    my %content = $self->content();
    die 'Missing action' unless $content{'action'};

    my $action;
    foreach my $a (@{$self->_info()->{'supported_actions'}->{'CC'}}) {
        if (lc $a eq lc $content{'action'}) {
            $action = $a; last;
        }
    }
    die 'Unsupported action' unless $action;

    my $result       = $mock_responses->{$action}->{$content{'card_number'}} || $default_mock;
    my $order_number = $result->{'order_number'};
    $order_number    = ref $order_number eq 'CODE' ? $order_number->() : $order_number;

    $self->error_message( $result->{'error_message'} );
    $self->result_code( $result->{'error_code'} );
    $self->is_success( defined $result->{'result'} && $result->{'result'} =~ /^9|11$/ ? 1 : 0 );
    $self->order_number($order_number); # sale vs Authorization

    return $result;
}

1;
