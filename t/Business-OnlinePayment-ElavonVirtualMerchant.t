#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Business-OnlinePayment-ElavonVirtualMerchant.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Business::OnlinePayment::ElavonVirtualMerchant') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $base = 'Business::OnlinePayment';
my $processor = 'ElavonVirtualMerchant';

my $obj = new $base($processor);

isa_ok($obj, $base, "ISA $base");
isa_ok($obj, "$base::$processor", "ISA $base::$processor");

# BOP mandatory methods
can_ok($obj, qw/content submit is_success failure_status result_code test_transaction/);
can_ok($obj, qw/require_avs transaction_type error_message authorization server port path/);

my ($server, $port, $path) = ("www.myvirtualmerchant.com", 443, "/process.do");

is($obj->server, $server, "Server: $server");
is($obj->port, $port, "Port: $port");
is($obj->path, $path, "Path: $path");

