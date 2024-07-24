# iptables-management-script

This repository contains a script to manage iptables rules for allowing and blocking specific ports and services on a Linux server.

## Features

- Open and close ports dynamically using port numbers or service names.
- Manage allowed IP addresses for HTTP and HTTPS traffic.
- Persist iptables rules across reboots using systemd.

## Prerequisites

- Linux operating system.
- `iptables` installed on your system.
- `systemd` for persisting iptables rules.

## Installation

1. **Clone the Repository**:

    ```bash
    git clone https://github.com/Matt-THG/iptables-management-script.git
    cd iptables-management-script
    ```

2. **Make the Script Executable**:

    ```bash
    chmod +x iptables_rules.sh
    ```

## Usage

### Running the Script

To run the script, use the following command:

```bash
./iptables_rules.sh [OPTIONS]
```
## Options
```--open PORT/SERVICE: Open the specified port or service.```

```--close PORT/SERVICE: Close the specified port or service.```


## Examples
### Open HTTP and Redis ports:
```bash 
./iptables_rules.sh --open http --open redis
```
### Close Redis port:
```bash
./iptables_rules.sh --close redis
```

## Configuration
You can specify allowed IP addresses for HTTP and HTTPS traffic in the allowed_ips.conf file. Each line should contain a single IP address.


## Troubleshooting
Invalid Service: If you receive an "Invalid service" message, ensure the service name is correct and exists in /etc/services.

Permission Denied: Make sure you run the script with root privileges using sudo.


## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request.
