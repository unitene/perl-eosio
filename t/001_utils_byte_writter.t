#!/usr/bin/perl
use uni::perl;
use Data::Dumper;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

require_ok 'EOSIO::Utils::EOSByteWriter' or BAIL_OUT("EOSIO::Utils::EOSByteWriter can't be loaded");

is(EOSIO::Utils::EOSByteWriter->new()->put_char(ord('A'))->to_hex, '41', 'put_char');
is(EOSIO::Utils::EOSByteWriter->new()->put_char(1)->to_hex, '01', 'put_char');
is(EOSIO::Utils::EOSByteWriter->new()->put_short_le(12)->to_hex, '0c00', 'put_short_le');
is(EOSIO::Utils::EOSByteWriter->new()->put_uint_le(10*256*256*256)->to_hex, '0000000a', 'put_uint_le');
is(EOSIO::Utils::EOSByteWriter->new()->put_ulong_le(Math::BigInt->new('0x0b00fffff1')->to_base(10))->to_hex, 'f1ffff000b000000', 'put_ulong_le');
is(EOSIO::Utils::EOSByteWriter->new()->put_bytes(chr(0xff).chr(0x0a))->to_hex, 'ff0a', 'put_bytes');
is(EOSIO::Utils::EOSByteWriter->new()->put_variable_uint(360)->to_hex, 'e802', 'put_variable_uint');
is(EOSIO::Utils::EOSByteWriter->new()->put_string('')->to_hex, '00', 'put_string(\'\')');
is(EOSIO::Utils::EOSByteWriter->new()->put_string('blabla')->to_hex, '06626c61626c61', 'put_string(\'blabla\')');

done_testing();
