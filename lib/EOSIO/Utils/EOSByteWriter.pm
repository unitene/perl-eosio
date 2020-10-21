package EOSIO::Utils::EOSByteWriter;
use uni::perl;
use Encode qw/encode_utf8/;
use feature 'signatures';
use Math::BigInt;
use Data::Dumper;

use Moo;
no if $] >= 5.018, warnings => "experimental";

sub BUILD {
    my ($self) = @_;
    $self->{buf} //= '';
}

sub put_char($self, $c) {
    $self->{buf} .= pack "C", int($c);
    $self;
}

sub put_short_le($self, $val) {
    $self->{buf} .= pack "v", int($val);
    $self;
}

sub put_uint_le($self, $val) {
    $self->{buf} .= pack "V", int($val);

    $self;
}

sub put_ulong_le($self, $val) {
    $val = Math::BigInt->new($val) unless ref $val;

    my $mask = Math::BigInt->new('0xffffffff');
    $self->put_uint_le($val->copy()->band($mask)->to_base(10));
    $val->brsft(32);
    $self->put_uint_le($val->band($mask)->to_base(10));

    $self;
}

sub put_bytes($self, $val) {
    $self->{buf} .= $val;
    $self;
}

sub put_variable_uint($self, $val) {
    $val = Math::BigInt->new($val) unless ref $val;

    while(not $val->is_zero) {
        $b = $val->copy()->band(0x7f);
        $val->brsft(7);
        $b->bior($val->is_zero ? 0 : 0b10000000);
        $self->put_char($b->to_base(10));
    }
    $self;
}

sub put_string($self, $str) {
    unless($str) {
        $self->put_char(0);
    } else {
        $self->put_variable_uint(length($str));
        $self->put_bytes($str);
    }
    $self;
}

sub to_hex {
    my $self = shift;
    unpack "H*" => $self->{buf};
}

1;