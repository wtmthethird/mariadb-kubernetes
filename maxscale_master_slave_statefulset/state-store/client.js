/* Copyright (C) 2018 MariaDB Corporation
 *
 * Implements a state store client.
 *
 * Three different modes of operation are supported:
 *
 * maxscale: every second reads the passive state, sends a heartbeat request 
 *           and, if active, also the ip of the current master. Based on the 
 *           response, uses MaxScale's REST API to align the localhost 
 *           configuration.
 *
 * mariadb-init: sends a single heartbeat request to receive the ip address
 *           of the current master and store it in the file system.
 *
 * mariadb:  sends a heartbeat request every second to keep the state store 
 *           aware of its liveness.
 */

var http = require("http");
var fs = require('fs');

var instance = 'maxscale';
var status = 'passive';
var service = "localhost";
var outputDirectory = ".";
var master = null;

function handleHttpResponse( response, onSuccess, onError ) {
    if( response.statusCode < 200 || response.statusCode > 299 ) {
        console.log( "Received error response: " + response.statusCode + ", " + response.status );
        
        if( onError !== undefined ) {
            onError( new Error("Server response: " + response.statusCode) );
        }
    } else {
        var chunks = [];

        response.on('socket', function (socket) {
            socket.setKeepAlive(true, 0);
            socket.setNoDelay(true);
        });

        response.on('data', (chunk) => {
            chunks.push( chunk );
        });
        
        response.on('end', (v) => {
            var json = {};

            if( chunks.length > 0 ) {
                var data = Buffer.concat(chunks).toString( "UTF-8" );
                json = JSON.parse(data);
            }

            if( onSuccess !== undefined )
                onSuccess( json );
        });

        response.on('error', (err) => {
            console.error( "Failed to read API response", err );

            if( onError !== undefined )
                onError(err);
        });
    }
}

function maxscaleAPI( method, api, data, onSuccess, onError ) {
    var contentType = 'application/json'; // (method == 'PATCH'?'application/json-patch':'application/json');
    var username = 'admin';
    var password = 'mariadb';
    var auth = 'Basic ' + Buffer.from(username + ':' + password).toString('base64');
    var jsonData;
    var headers = { 
        'Accept': 'application/json',
        'Accept-Charset': 'UTF-8', 
        'Authorization' : auth 
    };

    if( data != null ) {
        jsonData = JSON.stringify(data);
        headers['Content-Length'] = Buffer.byteLength(jsonData);
        headers['Content-Type'] = contentType;
    } else {
        jsonData = null;
    }

    var options = { host: 'localhost',
                    port: 8989,
                    method: method,
                    path: '/v1/' + api,
                    headers: headers
     };

    var request = http.request( options, (resp) => { handleHttpResponse( resp, onSuccess, onError ); } );
    if( jsonData != null ) {
        request.write( jsonData );
    } 
    request.end();
}

function updateMaxscaleStatus( response ) {
    var newStatus = response['status'];
    if( newStatus != status )
        setImmediate( (newStatus) => {
            console.log('Updating status to ' + newStatus.toUpperCase() );
            var patch = [ { op: "replace", path: "data.attributes.parameters.passive", value: !(newStatus == 'active') } ];
            var statusUpdate = { data: { 
                attributes: {
                    parameters: {
                        passive: !(newStatus == 'active')
                    }
                }
            }};
            
            maxscaleAPI("PATCH", "maxscale", statusUpdate, () => { 
                status = newStatus;
                console.log( 'Successfully updated status to ' + newStatus.toUpperCase() );
            }, (error) => {
                console.log( 'Failed to update status to ' + newStatus.toUpperCase(), error );
            });
        }, newStatus );

    setImmediate( (cluster) => { checkClusterStatus(cluster); }, response['cluster'] );
}

function deleteServer( server ) {
    console.log("Removing service associations for " + server );

    var json = {"data":{"relationships":{"services": {"data":[]},"monitors": {"data":[]}}}}
    // first remove service associations 
    maxscaleAPI( "PATCH",  "servers/" + encodeURI(server), json, ()=> {
        console.log("Succesfully removed service associations for " + server );
        console.log("Deleting server " + server );

        // and then delete
        maxscaleAPI( "DELETE", "servers/" + encodeURI(server), null, ()=> {
            console.log("Successfully deleted server " + server );
        }, (err) => {
            console.log("Failed to delete server " + server, err);
        });
    }, (err)=> {
        console.log("Failed to remove service associations for " + server, err );
    } );
}

function addServer( server ) {
    var json = {
		data: {
		  id: server,
		  type: "servers",
		  attributes: {
			parameters: {
			  address: server,
			  port: 3306,
			  protocol: "MariaDBBackend"
            },
            master_id: master
		  },
		  relationships: {
			services: {
			  data: [
				{
				  id: "Read-Write-Service",
				  type: "services"
				},
				{
				  id: "Read-Only-Service",
				  type: "services"
				}
			  ]
			},
			monitors: {
			  data: [
				{
				  id: "MariaDB-Monitor",
				  type: "monitors"
				}
			  ]
			}
		  }
		}
      };
      
    console.log("Adding server " + server );
    maxscaleAPI( "POST", "servers", json, ()=> {
        console.log("Successfully added server " + server );
    }, (err) => {
        console.log("Failed to add server " + server, err);
    });
}

function alignClusterStatus( heartbeatServers, maxscaleServers ) {
    // get the difference between the two sets
    var hSrv = {};
    var mSrv = {};

    for( var i=0; i<heartbeatServers.length; i++) {
        hSrv[ heartbeatServers[i] ] = true;
    }

    for( var i=0; i<maxscaleServers['data'].length; i++ ) {
        mSrv[ maxscaleServers['data'][i].attributes.parameters.address ] = maxscaleServers['data'][i].id;

        if( status == 'active' && maxscaleServers['data'][i].attributes.state == 'Master, Running' ) {
            master = maxscaleServers['data'][i].attributes.parameters.address;
        }
    }

    // delete the servers that are in Maxscale, but not in state server
    for( var server in mSrv ) {
        if( !(server in hSrv) ) 
            setImmediate( deleteServer, mSrv[server] );
    }

    // add the servers that are in state server, but not in Maxscale
    for( var server in hSrv ) {
        if( !(server in mSrv) ) 
            setImmediate( addServer, server );
    }
}

function checkClusterStatus(servers) {
    maxscaleAPI( "GET", "servers", null, (data) => {
        alignClusterStatus(servers, data);
    }, (error) => {
        console.log( "MaxScale API call error", error );
    } );
}

// checks maxscale status and sends a heartbeat
function checkMaxscaleStatus( data ) {
    var isPassive = data[ 'data' ]['attributes']['parameters']['passive'];
    status = isPassive?'passive':'active';

    setImmediate( () => { sendHeartbeat( updateMaxscaleStatus ); } );
}

// send a heartbeat to status server
function sendHeartbeat( success ) {
    // heartbeat endpoint
    var url = '/heartbeat/' + instance + '/' + status + '/' + (master == null ? 'na' : master );
    var request = { host: service, 
                    port: 80,
                    path: url,
                    headers: { 'Accept': 'application/json', 'Accept-Charset': 'UTF-8' }
    };

    var message = http.get( request, (resp) => { handleHttpResponse( resp, 
    success,
    (error) => {
        console.error( "Could not send heartbeat", error );
    }) } );
}

// execute on schedule (1 seconds)
function heartbeat() {
    if( instance == "maxscale" ) {
        maxscaleAPI( "GET", "maxscale", null, (data) => {
            checkMaxscaleStatus(data);
        }, (error) => {
            console.log( "MaxScale API call error", error );
        } );
    } else if( instance == "mariadb") {
        sendHeartbeat( () => {} );
    } else if( instance == "mariadb-init" ) {
        sendHeartbeat( (data) => {
            var master;
            if( data['isMaster'] == true ) {
                master = 'localhost';
            } else {
                master = data['master'];
            }

            fs.writeFile( outputDirectory + "/master", master, function( err ) {
                if( err ) {
                    console.error( "Could not write master to file system" );
                    process.exit(1);
                } else {
                    process.exit();
                }
            });
        });
    }
}

process.on('uncaughtException', function (err) {
    console.log('Unsuccessful heartbeat ', err );
});

instance = process.argv[2];
service = process.argv[3];

if( instance == "mariadb-init" )
    outputDirectory = process.argv[4];

if( instance != 'maxscale' ) status = 'server';
setInterval( heartbeat, 1000 );
