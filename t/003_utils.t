#!/usr/bin/perl
use uni::perl;
use Data::Dumper;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

require_ok 'EOSIO::Utils' or BAIL_OUT("EOSIO::Utils can't be loaded");

is EOSIO::Utils::name_to_long('vfgqixdelcfy'), '15769749323137030112', 'name_to_long: ok';
is EOSIO::Utils::long_to_name('15769749323137030112'), 'vfgqixdelcfy', 'long_to_name: ok';

done_testing();

