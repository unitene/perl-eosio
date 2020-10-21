#!/usr/bin/perl
use uni::perl;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use EOSIO::Utils 'decode_json';

require_ok 'EOSIO::Utils::Transaction' or BAIL_OUT("EOSIO::Utils::Transaction can't be loaded");

my $tx = {
    'expiration'             => '2020-10-21T02:32:01',
    'max_net_usage_words'    => 0,
    'ref_block_num'          => 64977,
    'ref_block_prefix'       => 1667352095,
    'transaction_extensions' => [],
    'context_free_data'      => [],
    'signatures'             => [
        'SIG_K1_KYPE1FanWtWsMQS5YoU4zCeJfJpT85dZS5VwzsGVTn4MZrBzMgQ4kd8TxoyfhmmaxGGJKdVpYZwXc6MPeU5ox997HzBxdM'
    ],
    'context_free_actions'   => [],
    'actions'                => [
        {
            'authorization' => [
                {
                    'permission' => 'owner',
                    'actor'      => 'vfgqixdelcfy'
                }
            ],
            'name'          => 'transfer',
            'data'          => 'e0178a2a7567d9dac03983fabfbba6d1102700000000000004544e54000000000f63726561746564206279207065726c',
            'account'       => 'eosio.token'
        }
    ],
    'delay_sec'              => 0,
    'max_cpu_usage_ms'       => 0
};

is EOSIO::Utils::Transaction::pack($tx), 'a19d8f5fd1fd1fc66163000000000100a6823403ea3055000000572d3ccdcd01e0178a2a7567d9da0000000080ab26a730e0178a2a7567d9dac03983fabfbba6d1102700000000000004544e54000000000f63726561746564206279207065726c00', 'pack';

done_testing();

