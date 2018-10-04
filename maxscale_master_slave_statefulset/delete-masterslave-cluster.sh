#!/bin/bash
# Copyright (C) 2018 MariaDB Corporation
# Destroys templatized master-slave cluster fronted by MaxScale in Kubernetes
# User-defined parameters are "application" and "environment"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/create-masterslave-cluster.sh "$@" --delete
