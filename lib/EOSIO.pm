package EOSIO;
use uni::perl;
use Data::Dumper;
use AnyEvent;
use Try::Tiny;
use DateTime;
use EOSIO::Utils;

use EOSIO::Chain;
use EOSIO::Wallet;

use EOSIO::Providers::HTTP;
use EOSIO::Providers::Utils 'cb';
use EOSIO::Utils::Transaction;

use Moo;

has 'chain_url' => (is => 'rw', required => 1);
# has 'wallet_unix_socket_path' => (is => 'rw', required => 1);
has 'wallet_url' => (is => 'rw', required => 1);

has 'chain' => (is => 'rw', lazy => 1, builder => 1);
has 'wallet' => (is => 'rw', lazy => 1, builder => 1);

sub _build_chain {
    my $self = shift;
    EOSIO::Chain->new({
        provider => EOSIO::Providers::HTTP->new(url => $self->chain_url)
    });
}

sub _build_wallet {
    my $self = shift;
    EOSIO::Wallet->new({
        provider => EOSIO::Providers::HTTP->new(url => $self->wallet_url)
    });
}

sub push_actions {
    my ($self, $actions, $wallet, $keys, $cb) = @_;
    return $cb->([], 'OK') unless @$actions;

    my $cv = AnyEvent->condvar;
    foreach my $action (@$actions) {
        my $data = delete $action->{data};
        $cv->begin;
        $self->chain->abi_to_json($action->{account}, $action->{name}, $data, sub {
            my $result = shift;
            return $cv->croak($_[0]) unless $result;

            $action->{data} = $result->{binargs};
            $cv->end;
        });
    }

    $cv->cb(sub {
        my $cv = shift;

        my ($result, $error_msg) = try {
            $cv->recv;
            return 1;
        }
        catch {
            return (undef, $_);
        };
        return $cb->(undef, $error_msg) unless $result;

        $self->wallet->unlock($wallet->{name}, $wallet->{password}, cb $cb, sub {
            my $exp_time = DateTime->now()->add({ minutes => 30 })->strftime("%FT%T.000");
            $self->_get_block_info(cb $cb, sub {
                my $result = shift;
                my $chain_id = $result->{chain_id};
                my $tx = {
                    ref_block_num          => $result->{ref_block_num},
                    ref_block_prefix       => $result->{ref_block_prefix},
                    expiration             => $exp_time,
                    actions                => $actions,
                    signatures             => [],
                    context_free_actions   => [],
                    transaction_extensions => [],
                };
                $self->chain->get_required_keys($keys, $tx, cb $cb, sub {
                    $self->wallet->sign_transaction($tx, shift->{required_keys}, $chain_id, cb $cb, sub {
                        my $result = shift;
                        my $push = {
                            compression              => 'none',
                            signatures               => $result->{signatures},
                            packed_context_free_data => '',
                            packed_trx               => EOSIO::Utils::Transaction::pack($result),
                        };

                        $self->chain->push_transaction($push, $cb);
                    });
                });
            });
        });
    });
}

sub get_buy_ram_bytes_action {
    my ($payer, $receiver, $bytes, $authorization) = @_;

    return {
        account       => 'eosio',
        name          => 'buyrambytes',
        data          => {
            payer    => $payer,
            receiver => $receiver,
            bytes    => $bytes,
        },
        authorization => $authorization,
    }
}

sub get_delegate_bw_action {
    my ($from, $receiver, $cpu_q, $net_q, $authorization, $is_transfer) = (shift, shift, shift, shift, pop, shift);
    $is_transfer //= 1;
    return {
        account       => 'eosio',
        name          => 'delegatebw',
        authorization => $authorization,
        data          => {
            from               => $from,
            receiver           => $receiver,
            stake_cpu_quantity => $cpu_q,
            stake_net_quantity => $net_q,
            transfer           => $is_transfer ? EOSIO::Utils::json_true : EOSIO::Utils::json_false,
        }
    };
}

sub get_new_account_action {
    my ($creator, $name, $owner_key, $authorization, $active_key) = (shift, shift, shift, pop, shift);
    $active_key //= $owner_key;

    return {
        account       => 'eosio',
        name          => 'newaccount',
        authorization => $authorization,
        data          => {
            creator => $creator,
            name    => $name,
            owner   => {
                threshold => 1,
                keys      => [ { key => $owner_key, weight => 1 } ],
                accounts  => [],
                waits     => [],
            },
            active  => {
                threshold => 1,
                keys      => [ { key => $active_key, weight => 1 } ],
                accounts  => [],
                waits     => [],
            },
        }
    }
}

sub _get_block_info {
    my ($self, $cb) = @_;
    my $chain_id;
    $self->chain->get_info(cb $cb, => '_get_block_info' => sub {
        my $result = shift;
        $chain_id = $result->{chain_id};
        $self->chain->get_block($result->{head_block_num}, cb $cb, '_get_block_info', sub {
            my $result = shift;
            $cb->({
                ref_block_prefix => $result->{ref_block_prefix},
                ref_block_num    => $result->{block_num},
                chain_id         => $chain_id,
            });
        });
    });

}

1;