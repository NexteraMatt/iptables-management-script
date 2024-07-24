#!/bin/bash

CONFIG_FILE="allowed_ips.conf"
BACKUP_FILE="/etc/sysconfig/iptables.backup"

# Custom service mappings for non-standard services
declare -A CUSTOM_SERVICES
CUSTOM_SERVICES=( ["prometheus"]=9090 ["grafana"]=3000 )

# Function to validate IP addresses
validate_ip() {
  local ip=$1
  if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    return 0
  else
    echo "Invalid IP address format: $ip"
    return 1
  fi
}

# Function to resolve service name to port number
resolve_service_to_port() {
  local service=$1
  local protocol=${2:-tcp}
  if [[ -n ${CUSTOM_SERVICES[$service]} ]]; then
    echo "${CUSTOM_SERVICES[$service]}"
  else
    local port=$(getent services "$service/$protocol" | awk '{print $2}' | cut -d'/' -f1)
    echo "$port"
  fi
}

# Function to show usage information
usage() {
  echo "Usage: $0 [--open PORT/SERVICE ...] [--close PORT/SERVICE ...]"
  echo "Options:"
  echo "  --open PORT/SERVICE ...    Open the specified PORTs or SERVICEs"
  echo "  --close PORT/SERVICE ...   Close the specified PORTs or SERVICEs"
  echo "Examples:"
  echo "  $0 --open 80 443"
  echo "  $0 --close prometheus grafana"
  exit 1
}

# Function to initialize iptables
initialize_iptables() {
  # Allow all outgoing connections
  iptables -P OUTPUT ACCEPT

  # Allow all loopback (lo) traffic and drop all traffic to 127/8 that doesn't use lo0
  iptables -C INPUT -i lo -j ACCEPT 2>/dev/null || iptables -A INPUT -i lo -j ACCEPT
  iptables -C INPUT ! -i lo -s 127.0.0.0/8 -j REJECT 2>/dev/null || iptables -A INPUT ! -i lo -s 127.0.0.0/8 -j REJECT

  # Allow established and related incoming connections
  iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
}

# Function to apply IP address rules
apply_ip_rules() {
  if [[ -f "$CONFIG_FILE" ]]; then
    if [[ ! -s "$CONFIG_FILE" ]]; then
      echo "Configuration file $CONFIG_FILE is empty. Allowing any/any HTTP and HTTPS traffic."
      iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 80 -j ACCEPT
      iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    else
      while IFS= read -r ip; do
        # Skip empty lines and comments
        [[ -z "$ip" || "$ip" =~ ^# ]] && continue
        validate_ip "$ip"
        if [ $? -eq 0 ]; then
          iptables -C INPUT -p tcp -s "$ip" --dport 80 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp -s "$ip" --dport 80 -j ACCEPT
          iptables -C INPUT -p tcp -s "$ip" --dport 443 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp -s "$ip" --dport 443 -j ACCEPT
        else
          echo "Skipping invalid IP: $ip"
        fi
      done < "$CONFIG_FILE"
    fi
  else
    echo "Configuration file $CONFIG_FILE not found!"
    exit 1
  fi
}

# Function to apply port rules based on arguments
apply_port_rules() {
  local action=""
  local open_http_https=false
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      --open|--close)
        action=$1
        shift
        ;;
      *)
        if [[ -n $action ]]; then
          if [[ $1 =~ ^[0-9]+$ ]]; then
            local port=$1
          else
            local port=$(resolve_service_to_port "$1")
            if [[ -z $port ]]; then
              echo "Invalid service: $1"
              usage
            fi
          fi
          if [[ $port == 80 || $port == 443 ]]; then
            open_http_https=true
          fi
          if [[ $action == "--open" ]]; then
            echo "Opening port/service $1 (resolved to port $port)..."
            iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
          elif [[ $action == "--close" ]]; then
            echo "Closing port/service $1 (resolved to port $port)..."
            iptables -D INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || echo "Port $port is not open."
          fi
        else
          echo "Unknown option: $1"
          usage
        fi
        shift
        ;;
    esac
  done

  # If opening ports, ensure HTTP and HTTPS are open if the config file is empty
  if [[ $action == "--open" && $open_http_https == false ]]; then
    apply_ip_rules
  fi
}

# Main script execution
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

if systemctl is-active --quiet firewalld; then
  echo "Disabling and stopping firewalld..."
  systemctl disable firewalld
  systemctl stop firewalld
fi

if ! command -v iptables &> /dev/null; then
  echo "iptables not found, installing..."
  yum install -y iptables iptables-services
fi

if [ -f /etc/sysconfig/iptables ]; then
  echo "Backing up existing iptables rules..."
  cp /etc/sysconfig/iptables $BACKUP_FILE || { echo "Failed to back up iptables rules"; exit 1; }
fi

initialize_iptables
apply_ip_rules
apply_port_rules "$@"

iptables -C INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7 2>/dev/null || iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

if iptables-save > /etc/sysconfig/iptables; then
  echo "iptables rules saved successfully."
else
  echo "Failed to save iptables rules."
  exit 1
fi

cat << EOF > /etc/systemd/system/iptables-restore.service
[Unit]
Description=Restore iptables firewall rules
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/iptables-restore /etc/sysconfig/iptables
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

if systemctl daemon-reload; then
  echo "Systemd daemon reloaded successfully."
else
  echo "Failed to reload systemd daemon."
  exit 1
fi

if systemctl enable iptables-restore; then
  echo "iptables-restore service enabled."
else
  echo "Failed to enable iptables-restore service."
  exit 1
fi

if systemctl start iptables-restore; then
  echo "iptables-restore service started successfully."
else
  echo "Failed to start iptables-restore service."
  exit 1
fi

echo "iptables rules applied successfully."
iptables -L -v
