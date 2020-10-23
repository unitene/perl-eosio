package EOSIO::Wallet;
use uni::perl;
use Data::Dumper;
use EOSIO::Providers::Utils qw/add_msg_cb/;

use Moo;

has 'provider' => (is => 'rw', required => 1);

sub unlock {
    my ($self, $wallet_name, $password, $cb) = @_;
    my $w_cb = add_msg_cb 'unlock', $cb;
    $self->provider->post_request('/v1/wallet/unlock', [$wallet_name, $password], sub {
        my ($result, $error_msg) = @_;
        if(not $result and $error_msg =~ /^Wallet is already unlocked/) {
            return $cb->(1, 'OK');
        } else {
            $w_cb->(@_);
        }
    });
}

sub sign_transaction {
    my ($self, $fields, $key_list, $chain_id, $cb) = @_;
    $self->provider->post_request('/v1/wallet/sign_transaction', [$fields, $key_list, $chain_id], add_msg_cb 'sign_transaction' => $cb);
}

1;