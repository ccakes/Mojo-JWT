#!/usr/bin/env perl

use Test::More;

use Mojo::JWT;

my $has_rsa = eval { require Crypt::OpenSSL::RSA; 1 };

my $payload = {foo => 'bar'};

{
    my $name = 'encodes and decodes JWTs';
    my $secret = 'secret';
    my $jwt = Mojo::JWT->new(claims => $payload, secret => $secret)->encode;
    my $decoded_payload = Mojo::JWT->new(secret => $secret)->decode($jwt);
    is_deeply $decoded_payload, $payload, $name;
}

{
    my $name = 'encodes and decodes JWTs for HS512 signaturese';
    my $jwt = Mojo::JWT->new(claims => $payload, secret => 'S3cR3t', algorithm => 'HS512')->encode;
    my $decoded_payload = Mojo::JWT->new(secret => 'S3cR3t')->decode($jwt);
    is_deeply $decoded_payload, $payload, $name;
}

SKIP: {
    skip 'requires Crypt::OpenSSL::RSA', 1 unless $has_rsa;
    my $name = 'encodes and decodes JWTs for RSA signaturese';
    my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);
    my $jwt = Mojo::JWT->new(claims => $payload, secret => $rsa->get_private_key_string, algorithm => 'RS512')->encode;
    my $decoded_payload = Mojo::JWT->new(public => $rsa->get_public_key_string)->decode($jwt);
    is_deeply $decoded_payload, $payload, $name;
}

{
    my $name = 'decodes valid JWTs';
    my $example_payload = {hello => 'world'};
    my $example_secret = 'secret';
    my $example_jwt = 'eyJhbGciOiAiSFMyNTYiLCAidHlwIjogIkpXVCJ9.eyJoZWxsbyI6ICJ3b3JsZCJ9.tvagLDLoaiJKxOKqpBXSEGy7SYSifZhjntgm9ctpyj8';
    my $decoded_payload = Mojo::JWT->new(secret => $example_secret)->decode($example_jwt);
    is_deeply $decoded_payload, $example_payload, $name;
}

{
    my $name = 'raises exception with wrong hmac key';
    my $right_secret = 'foo';
    my $bad_secret = 'bar';
    my $jwt_message = Mojo::JWT->new(claims => $payload, secret => $right_secret, algorithm => 'HS256')->encode;
    eval {
        Mojo::JWT->new(secret => $bad_secret)->decode($jwt_message);
    };
    like $@, qr/^Failed HS validation/, $name;
}

SKIP: {
    skip 'requires Crypt::OpenSSL::RSA', 1 unless $has_rsa;
    my $name = 'raises exception with wrong rsa key';
    my $right_rsa = Crypt::OpenSSL::RSA->generate_key(1024);
    my $bad_rsa = Crypt::OpenSSL::RSA->generate_key(1024);
    my $jwt = Mojo::JWT->new(claims => $payload, secret => $right_rsa->get_private_key_string, algorithm => 'RS256')->encode;
    eval {
        Mojo::JWT->new(public => $bad_rsa->get_public_key_string)->decode($jwt);
    };
    like $@, qr/^Failed RS validation/, $name;
}

{
    my $name = 'allows decoding without key';
    my $jwt = Mojo::JWT->new(claims => $payload, algorithm => 'none')->encode;
    my $decoded_payload = Mojo::JWT->new(allow_none => 1)->decode($jwt);
    is_deeply $decoded_payload, $payload, $name;
}

{
    my $name = 'raises exception on unsupported crypto algorithm';
    eval {
        Mojo::JWT->new(claims => $payload, secret => 'secret', algorithm => 'HS131')->encode;
    };
    like $@, qr/^Unsupported HS signing algorithm/, $name;
}

done_testing;
