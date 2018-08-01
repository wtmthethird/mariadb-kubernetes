#!/bin/perl
#
# (C) 2018, MariaDB
#
# This script is used by the init container of a MariaDB pod and 
# registers the current host with MaxScale using the REST API. 
#
# It takes the following positinal arguments for the REST API:
#
# * FQDN of the host to be added
# * protocol, e.g. http or https
# * host, e.g. app-prod-mdb-mxs-0.app-prod-mdb-clust
# * post, e.g. 8989
# * username
# * password
# 
# If successful, the scripts outputs the hostname of the active 
# master. If the output is an empty string, this is the first instance
# that is being added to MaxScale
# 
 
use HTTP::Tiny;
use JSON::Tiny qw(decode_json encode_json);
    
my $host = $ARGV[0];
my $hostid = "";

# extract the server id from the hostname
if( $host =~ /([0-9]+)\./ ) {
    $hostid = $1;
} 
elsif( $host =~ /([0-9]+)$/ ) {
    $hostid = $1;
}
die "Unexpected hostname format " . $host if $hostid eq '';

# get arguments. TODO: sanitize inputs
my $apiProtocol = $ARGV[1];
my $apiHost = $ARGV[2];
my $apiPort = $ARGV[3];
my $apiUser = $ARGV[4];
my $apiPassword = $ARGV[5];

# define REST API endpoint
my $baseurl = $apiProtocol . '://' . $apiUser . ':' . $apiPassword . '@' . $apiHost . ':' . $apiPort . '/v1/';

my $http = HTTP::Tiny->new( default_headers => {
'Accept-Charset' => 'utf8',
'Accept' => 'application/json',
'Content-Type' => 'application/json'
});

# unknown master
my $masterhost = '';
my $configured = 0;

GET_SERVER_LIST: while( $configured==0 && $masterhost eq '' ) {
    # keep polling list of servers registered in MaxScale
    my $response = $http->get( $baseurl . 'servers' );

    # wait for maxscale API to become available, ignore network errors
    if( $response->{status} != 599 ) {
        die "Error fetching servers!\n" . $response->{status} unless $response->{success};

        my $json = decode_json $response->{content};
        my $servers = %$json{'data'};

        # if no servers in MaxScale, then make this one the master
        if( scalar @$servers == 0 ) {
            last GET_SERVER_LIST;
        }

        foreach my $server (@$servers) {
            my $serverid = %$server{'id'};
	    my $attributes = %$server{'attributes'};
            my $parameters = %$attributes{'parameters'};
	    my $address = %$parameters{'address'};
	    my $state = %$attributes{'state'};

            if( $address eq $host ) { 
	        # server already registered, make sure it will not be added a second time 
	        $configured = 1;
            }

            if( $state eq 'Master, Running' ) {
                # it's a running master, store the address
	        $masterhost = $address;
            }
        }
    }

    # still waiting for an active master
    # check back in 5 sec if a new master has been promoted
    if( $configured==0 && $masterhost eq '') {
        sleep 5;
    }
}

if( $masterhost eq '' ) {
    $masterhost = 'NO MASTER';
}

print $masterhost;
exit 0 if $configured != 0;

# server not registered, we need to register it
# register with monitors and services
$json = encode_json {
   'data' => {
      'id' => 'mariadb-' . $hostid,
      'type' => 'servers',
      'attributes' => {
         'parameters' => {
            'address' => $host,
             'port' => 3306,
             'protocol' => 'MariaDBBackend'
         }
      },
      'relationships' => {
         'services' => {
            'data' => [ { 'id' => 'Read-Write-Service', 'type' => 'services' }, { 'id' => 'Read-Only-Service', 'type' => 'services' } ]
         },
         'monitors' => {
            'data' => [ { 'id' => 'MariaDB-Monitor', 'type' => 'monitors' } ]
         }
      }
   }
};

my $response = $http->post( $baseurl . 'servers', { 'content' => $json } );
die "Error adding server!\n" . $response->{status} unless $response->{success};
