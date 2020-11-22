package EOSIO::Chain;
use uni::perl;
use Data::Dumper;
use EOSIO::Utils qw/cb utf8ToHex encode_json/;
use EOSIO::Providers::Utils qw/add_msg_cb/;

use Moo;

has 'provider' => (is => 'rw', required => 1);

sub abi_to_json {
    my ($self, $code, $action, $args, $cb) = @_;
    $self->provider->post_request('/v1/chain/abi_json_to_bin', {
        code   => $code,
        action => $action,
        args   => $args,
    }, cb $cb, 'abi_to_json', $cb);
}

sub get_info {
    my ($self, $cb) = @_;
    $self->provider->post_request('/v1/chain/get_info', add_msg_cb 'get_info' => $cb);
}

sub get_block {
    my ($self, $block_num_or_id, $cb) = @_;
    $self->provider->post_request('/v1/chain/get_block', { 'block_num_or_id' => $block_num_or_id }, add_msg_cb 'get_block' => $cb);
}

sub get_required_keys {
    my ($self, $key_list, $tx, $cb) = @_;
    $self->provider->post_request('/v1/chain/get_required_keys', { transaction => $tx, available_keys => $key_list }, add_msg_cb 'get_required_keys' => $cb);
}

sub push_transaction {
    my ($self, $tx, $cb) = @_;
    $self->provider->post_request('/v1/chain/push_transaction', $tx, add_msg_cb 'push_transaction' => $cb);
}

sub get_account {
    my ($self, $account_name, $cb) = @_;
    $self->provider->post_request('/v1/chain/get_account', { account_name => $account_name }, add_msg_cb 'get_account' => $cb);
}

sub get_currency_balance {
    my ($self, $account, $c_name, $sym, $cb) = @_;
    my $data = {
        "account" => $account,
        "code"    => $c_name,
        "symbol"  => $sym,
    };
    $self->provider->post_request('/v1/chain/get_currency_balance', $data, add_msg_cb 'get_currency_balance' => $cb);
}

1;