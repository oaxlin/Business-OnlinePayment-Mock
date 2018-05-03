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
use parent Business::OnlinePayment::HTTPS;
$me      = 'Business::OnlinePayment::Mock';

# VERSION
# PODNAME: Business::OnlinePayment::Mock
# ABSTRACT: Business::OnlinePayment::Mock - A backend for mocking fake results for test cards


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
    my $test_mode = shift;
    if (! defined $test_mode) { $test_mode = $self->{'test_transaction'} || 0; }
    $self->{'test_transaction'} = $test_mode;
    # normally we'd set server/port/path here but we aren't real so there isn't anything to set
    $self->server('');
    $self->port('');
    $self->path('');
    return $self->{'test_transaction'};
}

=method submit

Submit the content to the mocked API

=cut

sub submit {
    my $self = shift;
    my %content = $self->content();
    die 'Missing action' unless $content{'action'};

    my $action;
    foreach my $a (@{$self->_info()->{'supported_actions'}->{'CC'}}) {
        if (lc $a eq lc $content{'action'}) {
            $action = lc('_'.$a);
            $action =~ s/ /\_/g;
        }
    }
    if (exists $mock_responses->{$action}) {
        my $res = {};
        $self->error_message( $res->{'error_message'} );
        $self->result_code( $res->{'error_code'} );
        $self->is_success( defined $res->{'result'} && $res->{'result'} =~ /^9|11$/ ? 1 : 0 );
        $self->order_number( $res->{'x_document'} // $res->{'x_auth_id'} ); # sale vs auth
        return $res;
    } else {
        die 'Unsupported action';
    }
}

1;
