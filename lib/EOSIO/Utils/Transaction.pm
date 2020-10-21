package EOSIO::Utils::Transaction;
use uni::perl;
use feature 'signatures';

use Data::Dumper;
use DateTime::Format::DateParse;

use EOSIO::Utils::EOSByteWriter;

sub pack($tx) {
    my $dt = DateTime::Format::DateParse->parse_datetime($tx->{expiration}, 'UTC');
    my $w = EOSIO::Utils::EOSByteWriter->new;
    $w->put_uint_le($dt->epoch());
    $w->put_short_le($tx->{ref_block_num} & 0xffff);
    $w->put_uint_le($tx->{ref_block_prefix} & 0xffffffff);
    $w->put_variable_uint($tx->{max_net_usage_words});
    $w->put_variable_uint($tx->{max_cpu_usage_ms});
    $w->put_variable_uint($tx->{delay_sec});

    serialize_collection(\&serialize_action, $w, $tx->{context_free_actions});
    serialize_collection(\&serialize_action, $w, $tx->{actions});

    serialize_collection(sub {die 'serialize transaction_extensions not supported'}, $w, []); # $tx->{transaction_extensions}
    $w->to_hex;
}

sub serialize_collection {
    my ($cb, $w, $list) = @_;
    $w->put_variable_uint(scalar @$list);
    foreach (@$list) {
        $cb->($w, $_)
    }
}

sub serialize_action {
    my ($w, $action) = @_;
    $w->put_ulong_le(EOSIO::Utils::name_to_long($action->{account}));
    $w->put_ulong_le(EOSIO::Utils::name_to_long($action->{name}));

    serialize_collection(\&serialize_authorization, $w, $action->{authorization});

    if($action->{data}) {
        my $data = pack "H*" => $action->{data};
        $w->put_variable_uint(length($data));
        $w->put_bytes($data);
    } else {
        $w->put_variable_uint(0);
    }
}

sub serialize_authorization {
    my ($w, $auth) = @_;
    $w->put_ulong_le(EOSIO::Utils::name_to_long($auth->{actor}));
    $w->put_ulong_le(EOSIO::Utils::name_to_long($auth->{permission}));
}

1;