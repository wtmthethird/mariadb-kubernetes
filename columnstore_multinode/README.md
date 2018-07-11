# Kubernetes setup for mariadb Columnstore with 1 UM and 2 PM nodes

## Requirements

- a Kubernetes environment
- a DNS service inside the Kubernetes environment

## Installation

- use `kubectl` to create all 3 services
- create the `pm2` and `um` deplouments
- create the `pm1` deployment after the other 2 are already running
