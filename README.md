# iptables-management-script

This repository contains a script to manage iptables rules for allowing and blocking specific ports and services on a Linux server.

## Features

- Open and close ports dynamically using port numbers or service names.
- Manage allowed IP addresses for HTTP and HTTPS traffic.
- Persist iptables rules across reboots using systemd.

## Usage

### Running the Script

To run the script, use the following command:

```bash
./iptables_rules.sh [OPTIONS]
```
## Options
```--open PORT/SERVICE: Open the specified port or service.```

```--close PORT/SERVICE: Close the specified port or service.```

### Open HTTP and Redis ports:
```bash 
./iptables_rules.sh --open http --open redis
```
### Close Redis port:
```bash
./iptables_rules.sh --close redis
```
