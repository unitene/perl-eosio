package EOSIO;
use uni::perl;
use Data::Dumper;
use AnyEvent;
use Try::Tiny;

use EOSIO::Chain;
use EOSIO::Wallet;

use EOSIO::Providers::HTTP;
use EOSIO::Providers::Utils 'cb';

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
    my ($last_block, $ref_block_prefix, $chain_id);

    $cv->begin;
    $self->chain->get_info(sub {
        my $result = shift;
        return $cv->croak($_[0]) unless $result;
        $chain_id = $result->{chain_id};

        $self->chain->get_block($result->{head_block_num}, sub {
            my $result = shift;
            return $cv->croak($_[0]) unless $result;
            $ref_block_prefix = $result->{ref_block_prefix};
            $last_block = $result->{block_num};
            $cv->end;
        });
    });

    $cv->begin;
    foreach my $action(@$actions) {
        my $data = delete $action->{data};
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
        } catch {
            return (undef, $_);
        };
        return $cb->(undef, $error_msg) unless $result;

        $self->wallet->unlock($wallet->{name}, $wallet->{password}, cb $cb, sub {
            my $exp_time = DateTime->now()->add({ minutes => 30 })->strftime("%FT%T.000");
            my $tx = {
                ref_block_num          => $last_block,
                ref_block_prefix       => $ref_block_prefix,
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
    })
}

1;