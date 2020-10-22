package EOSIO::Chain;
use uni::perl;
use Data::Dumper;
use EOSIO::Utils qw/cb utf8ToHex encode_json/;

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
    $self->provider->post_request('/v1/chain/get_info', $cb);
}

sub get_block {
    my ($self, $block_num_or_id, $cb) = @_;
    $self->provider->post_request('/v1/chain/get_block', { 'block_num_or_id' => $block_num_or_id }, $cb);
}

sub get_required_keys {
    my ($self, $key_list, $tx, $cb) = @_;
    $self->provider->post_request('/v1/chain/get_required_keys', {transaction => $tx, available_keys => $key_list}, $cb);
}

sub push_transaction {
    my ($self, $tx, $cb) = @_;
    $self->provider->post_request('/v1/chain/push_transaction', $tx, $cb);
}

1;