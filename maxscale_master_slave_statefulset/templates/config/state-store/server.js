/* Copyright (C) 2018 MariaDB Corporation
 *
 * Runs a tiny state store server to maintain the state of an individual MariaDB cluster
 * made of several MariaDB instances in a Master/Slave or a Master/Master configuration
 * fronted by two or more redundant MaxScale instances in a HA configuration behind a
 * DNS load balancer.
 */

var express = require("express");
var bodyParser = require("body-parser");
var routes = require("./routes.js");
var app = express();
var http = require("http");

var server = http.createServer(app);

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

routes(app);

server.listen( 80, "0.0.0.0" ).on("listening", function () {
    console.log("MariaDB state server running on ", server.address().address, " port ", server.address().port);
});
