/* Copyright (C) 2018 MariaDB Corporation
 *
 * Implements the business logic of the state store. A single endpoint is provided:
 *
 * http://state-store/heartbeat/:type/:role/:master
 *
 * :type is maxscale or mariadb
 * :role is active/passive for maxscale, server for mariadb
 * :master is the name of the current master (only accepted from the active maxscale instance)
 *
 * The state store ensures that there is only one active MaxScale instance at a time.
 *
 * All pods in the cluster are expected to contain a sidecar container that maintains state by 
 * calling the heartbeat endpoint every second. The response is different depending on the type
 * of the instance.
 *
 * A MaxScale instance will send its current role (active/passive) and recieve JSON a response 
 * with the following structure:
 *
 * { id: <maxscale-ip>,
 *   status: <active or passive>,
 *   cluster: [ <list of server ips> ]
 * }
 *
 * Based on this response the state store client aligns the state of the MaxScale instance
 * running on the same pod.
 *
 * If the active MaxScale instance has not been heard from for 5 seconds or more, the state 
 * store will promote another MaxScale instance to be the active one.
 *
 * A MariaDB instance will receive the following response:
 *
 * { master: <master-ip>,
 *   is-master: <true or false>
 * }
 *
 * If no master has been announced to the state store by an active MaxScale instance, it 
 * will assume the first connected MariaDB server is the master.
 */

var firstSeen = (new Date()).getTime();
var clusterStatus = { currentActive: null, master: null, servers: {} }

function handleServerStatus( serverId ) {
  var timeNow = (new Date()).getTime()

  // no master set at the time of the first server checkin, set self as master
  if( clusterStatus['master'] == null ) {
    console.log( "(SERVER) Updating master to " + serverId );
    clusterStatus['master'] = serverId;
  }

  if( serverId in clusterStatus.servers ) {
    clusterStatus.servers[serverId]['lastSeen'] = timeNow;
  } else {
    console.log( "(SERVER) Adding server to cluster " + serverId );
    clusterStatus.servers[serverId] = { type: 'mariadb', lastSeen: timeNow, role: 'server' }
  }

  // return status of current node
  return { master: clusterStatus['master'], isMaster: clusterStatus['master'] == serverId };
}

// check for timeout of current active, promote new active if necessary
function handleMaxscaleStatus( serverId, isActive ) {
  var timeNow = (new Date()).getTime();

  if( !(serverId in clusterStatus.servers) ) {
    console.log( serverId + " (MAXSCALE) Not in cluster, registering" );
    console.log( serverId + ", " + JSON.stringify(clusterStatus) );

    if( isActive && clusterStatus['currentActive'] == null ) {
      clusterStatus['currentActive'] = serverId;
      console.log( serverId + ", (MAXSCALE) Changing current active to self" );
    }

    clusterStatus.servers[serverId] = { type: 'maxscale', lastSeen: timeNow }
    console.log( serverId + ", " + JSON.stringify(clusterStatus) );
  } else {
    var currentActive = clusterStatus['currentActive'];
    var timeSinceLastSeen;

    if( currentActive in clusterStatus.servers ) {
      timeSinceLastSeen = timeNow - clusterStatus.servers[currentActive]['lastSeen'];
    } else {
      timeSinceLastSeen = timeNow - firstSeen;
    }

    clusterStatus.servers[serverId]['lastSeen'] = timeNow;
    if( serverId != currentActive && timeSinceLastSeen > 5000 ) {
        clusterStatus['currentActive'] = serverId;
        console.log( serverId + ", (MAXSCALE) active not seen in " + timeSinceLastSeen + "ms, promoting self as ACTIVE" );
    }
  }

  var result = { id: serverId, status: serverId == clusterStatus['currentActive']?'active':'passive', cluster: [] };
  for (var key in clusterStatus.servers ) {
    if( clusterStatus.servers[key]['type'] == 'mariadb' && (timeNow - clusterStatus.servers[key]['lastSeen']) < 10000 )
      result[ 'cluster' ].push( key );
  }

  return result;
}

var appRouter = function (app) {
  app.get("/heartbeat/:type/:role/:master", function (req, res) {
    var resourceType = req.params.type;
    var resourceRole = req.params.role;
    var resourceMaster = req.params.master;
    var resourceAddress = req.connection.remoteAddress;
    var data;

    if( resourceType == "maxscale" ) {
      if( resourceRole == "active" && resourceMaster != "na" && clusterStatus['master'] != resourceMaster ) {
        console.log( "(MAXSCALE) Updating master to " + resourceMaster );
      }
        
      data = handleMaxscaleStatus( resourceAddress, resourceRole == "active" )
      res.status(200).send(data);
    } else if( resourceType == "mariadb" || resourceType == "mariadb-init" ) {
      data = handleServerStatus( resourceAddress );
      res.status(200).send(data);
    } else {
        res.status(400).send({ message: 'unrecognized resource type: ' + resourceType + ' and/or role: ' + resourceRole });
    }
  });

}

module.exports = appRouter;
