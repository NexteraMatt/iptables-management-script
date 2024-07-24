# iptables-management-script

This repository contains a script to manage iptables rules for allowing and blocking specific ports and services on a Linux server.

## Recent Changes

### Latest Version

- **Enhanced Flexibility for HTTP/HTTPS**: The script now ensures HTTP (port 80) and HTTPS (port 443) ports can be closed explicitly via command-line arguments. If neither port 80 nor port 443 is opened, the script will check the configuration file and apply any/any rules for these ports if the file is empty.
- **Better Error Handling**: Improved error messages and handling throughout the script.
- **Detailed Logging**: Added more detailed logging to help debug issues when the script is run.
- **Backup Verification**: Ensured the backup process is successful before proceeding with other actions.
- **Enhanced Usage Function**: Provided more detailed examples and instructions in the usage function.

### Previous Updates

- **Custom Service Mapping**: Added mappings for non-standard services like Prometheus and Grafana.
- **Initialization Improvements**: Set default policies and rules for loopback traffic and established connections.
- **Dynamic Port Management**: Allows for dynamic opening and closing of specified ports and services.
- **IP Configuration Handling**: Reads from a configuration file to apply specific IP rules for HTTP and HTTPS.

## Features

- **Open and Close Ports/Services**: Open or close multiple ports or services specified in the command line arguments.
- **Configuration File**: If the configuration file (`allowed_ips.conf`) is empty, HTTP and HTTPS traffic is allowed from any source. If the file contains IP addresses, only those IPs are allowed to access HTTP and HTTPS.
- **Custom Service Mapping**: Includes custom mappings for services like Prometheus and Grafana that might not be listed in the system's `/etc/services` file.
- **Persistence**: Saves iptables rules and ensures they are restored on system startup using a systemd service.


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
### Open multiple ports:
```bash
./iptables_rules.sh --open 3001 http prometheus 9100 grafana 8080
```
### Close multiple ports:
```bash
./iptables_rules.sh --close 3001 http prometheus 9100 grafana 8080
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
