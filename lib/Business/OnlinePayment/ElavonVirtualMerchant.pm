package Business::OnlinePayment::ElavonVirtualMerchant;
use base qw(Business::OnlinePayment::HTTPS);

use strict;
use warnings;

sub set_defaults {
    my $self = shift;

    $self->server("www.myvirtualmerchant.com") unless $self->server;
    $self->port(443) unless $self->port;
    $self->path("/VirtualMerchant/process.do") unless $self->path;
}

sub map_fields {
    my $self = shift;

    my %content = $self->content;

    # ACTION map: convert Business::OnlinePayment namespace to Elavon namespace
    my %actions = (
        'normal authorization => 'CCSALE',
        'authorization only => 'CCAUTHONLY',
        'credit => 'CCCREDIT',
#        'Post Authorization,
        'Recurring Authorization,
        'Modify Recurring Authorization,
        'Cancel Recurring Authorization
        'CCSALE) Auth Only() Credit() Force(CCFORCE) Balance Inquiry(CCBALINQUIRY
    );
    $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};

    # TYPE map: convert deprecated Business::OnlinePayment terms to modern terms
    # (Should be done in parent class...)
    my %types = (
        'visa'             => 'CC',
        'mastercard'       => 'CC',
        'american express' => 'CC',
        'discover'         => 'CC',
        'check'            => 'ECHECK',
    );
    $content{'type'} = $types{lc($content{'type'})} || $content{'type'};

    # Overwrite existing content
    $self->content(%content);
}

sub submit {
    my $self = shift;

    $self->map_fields;
    $self->remap_fields(
There are a bunch of parameters like ssl_merchant_email that could be set via the constructor.


        login          => ssl_merchant_id,
        password       => ssl_pin,
        action         => ssl_transaction_type,
        description    => ssl_description,
        amount         => ssl_amount,
        invoice_number => ssl_invoice_number,
        customer_id    => ssl_customer_code,
	name		=> ???? # split to first and last name?
        first_name     => ssl_first_name,
        last_name      => ssl_last_name,
        company        => ssl_company,
        address        => ssl_avs_address,
        city           => ssl_city,
        state          => ssl_state,
        zip            => ssl_avs_zip,
        country        => ssl_country,
        card_number    => ssl_card_number,
        expiration     => ssl_exp_date, # MMYY
        cvv2           => ssl_cvv2cvc2a,
	recurring_billing => unsupported #
        referer        => # Authorize.Net and similar limit submissions by referrer
        ship_first_name => ssl_ship_to_first_name,
        ship_last_name  => ssl_ship_to_last_name,
        ship_company    => ssl_ship_to_company,
        ship_address    => ssl_ship_to_address1,
        ship_city       => ssl_ship_to_city,
        ship_state      => ssl_ship_to_state,
        ship_zip        => ssl_ship_to_zip,
        ship_country    => ssl_ship_to_country,
        phone           => ssl_phone,
        fax             => 
        email           => ssl_email,
        customer_ip     =>


ssl_cvv2cvc2_indicator => [0/1/2/9]; # If type eq 'VISA' or cvv2 ne '';
0=Bypassed, 1=present, 2=Illegible, and 9=Not Present

# We should be able to submit raw tracks, but the developers' guide doesn't specify how to do this.

    my %post_data = $self->get_fields(qw/
        ssl_merchant_id
        ssl_pin
        ssl_transaction_type
        ssl_description
        ssl_amount
        ssl_invoice_number
        ssl_customer_code
        ssl_first_name
        ssl_last_name
        ssl_company
        ssl_avs_address
        ssl_city
        ssl_state
        ssl_avs_zip
        ssl_country
        ssl_card_number
        ssl_exp_date
        ssl_cvv2cvc2a
        ssl_ship_to_first_name
        ssl_ship_to_last_name
        ssl_ship_to_company
        ssl_ship_to_address1
        ssl_ship_to_city
        ssl_ship_to_state
        ssl_ship_to_zip
        ssl_ship_to_country
        ssl_phone
        ssl_email
        ssl_user_id
    /);
    $post_data{'ssl_test_mode'} = $self->test_transaction() ? 'TRUE' : 'FALSE';

    # Third part of the credentials for identifying a particlar "virtual terminal".
    $post_data{'ssl_user_id'} = $self->user_id() unless defined($post_data{'ssl_user_id'});

    $post_data{'ssl_show_form'} = 'FALSE'; # Force gateway into API mode
    $post_data{'ssl_result_format'} = 'ASCII'; # Force ASCII response; 2nd part of API mode

    my ($page, $server_response, %reply_headers) = https_post( \%post_data );

    # Results need to be split on line ending and then on first equals sign.
    my @lines = split '\r\n', $page;
    my %results = ();
    foreach (@lines) {
        $results{$1} = $2 if /^\s*(\w+)\s*=\s*(.*)\s*$/;
    }

    if (!defined($results{'ssl_result'})) {
    } elsif ($results{'ssl_result'}) {
        $self->is_success(1);
        $self->result_code($results{'ssl_result'});
    } else {
        $self->is_success(0);
        $self->result_code($results{'ssl_result'});
        $self->error_message($results{'ssl_result_message'});
        $self->authorization($results{'ssl_approval_code'});
    }
}

ssl_result=0
ssl_result_message=APPROVAL
ssl_txn_id=9621F9AD-E49E-4003-91BD-5C1B08569959
ssl_approval_codeN54032
ssl_cvv2_response=
ssl_avs_response=

ssl_result=1
ssl_result_message=This transaction request has not been approved. You may elect to use another form of payment to complete this transaction or contact customer service for additional options.


There's some similarity between the fields Elavon accepts for PINless debit and ECHECK:

	account_number => ssl_customer_number,
	account_type => ssl_account_type, # Account Type (0=checking, 1=saving)
Personal Checking, Personal Savings, Business Checking or Business Savings.

Supporting XML looks like it's just another layer of encoding and decoding.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Business::OnlinePayment::ElavonVirtualMerchant - Elavon Virtual Merchant backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment::ElavonVirtualMerchant(user_id => 'whatever');

  my $tx = new Business::OnlinePayment("ElavonVirtualMerchant");
    $tx->content(
        type           => 'VISA',
        login          => 'testdrive',
        password       => '', #password or transaction key
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        customer_id    => 'jsk',
        first_name     => 'Jason',
        last_name      => 'Kohles',
        address        => '123 Anystreet',
        city           => 'Anywhere',
        state          => 'UT',
        zip            => '84058',
        card_number    => '4007000000027',
        expiration     => '09/02',
        cvv2           => '1234', #optional
    );
    $tx->submit();

    if($tx->is_success()) {
        print "Card processed successfully: ".$tx->authorization."\n";
    } else {
        print "Card was rejected: ".$tx->error_message."\n";
    }

=head1 DESCRIPTION

This module lets you use the Elavon (formerly Nova Information Systems) Virtual Merchant real-time payment gateway, a successor to viaKlix, from an application that uses the Business::OnlinePayment interface.

You need an account with Elavon.  Elavon uses a three-part set of credentials to allow you to configure multiple 'virtual terminals'.  Since Business::OnlinePayment only passes a login and password with each transaction, you must pass the third item, the user_id, to the constructor.

Elavon offers a number of transaction types, including electronic gift card operations and 'PINless debit'.  Of these, only credit card transactions fit the Business::OnlinePayment model.

This module does not use Elavon's XML encoding.

=head1 SEE ALSO

Business::OnlinePayment, Elavon Virtual Merchant Developers' Guide

=head1 AUTHOR

Richard Siddall, E<lt>elavon@elirion.netE<gt>

=head1 BUGS

Duplicates code to handle deprecated 'type' codes.

Method for passing raw card track data is not documented by Elavon.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Richard Siddall.  This module is largely based on Business::OnlinePayment::AuthorizeNet by Ivan Kohler.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
