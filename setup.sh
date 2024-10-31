#!/bin/bash

# Load environment variables if .env file exists
if [ -f .env ]; then
  echo "Loading variables from .env file..."
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found. Prompting for input..."

  # Prompt user for each variable if not set
  read -p "Enter new username: " NEW_USER
  read -sp "Enter password for $NEW_USER: " NEW_USER_PASSWORD
  echo
  read -p "Enter SSH public key path (default: $HOME/.ssh/cvs_servers.pub): " SSH_PUBLIC_KEY_PATH
  SSH_PUBLIC_KEY_PATH=${SSH_PUBLIC_KEY_PATH:-$HOME/.ssh/cvs_servers.pub}
  read -p "Enter SSH server IP: " SSH_SERVER_IP
  read -p "Enter timezone (default: Europe/Berlin): " TIMEZONE
  TIMEZONE=${TIMEZONE:-Europe/Berlin}
  read -p "Enter hostname: " HOSTNAME
  read -p "Enter admin email for update notifications: " EMAIL
  read -p "Enter test email address for mail check: " TEST_EMAIL
  read -p "Enter email subject (default: Test Subject): " SUBJECT
  SUBJECT=${SUBJECT:-Test Subject}
  read -p "Enter email message (default: My message): " MESSAGE
  MESSAGE=${MESSAGE:-My message}
fi

# Update and Upgrade System
echo "Updating and upgrading the system..."
sudo apt update -qq --show-progress && sudo apt upgrade -y -qq --show-progress

# Create a New User and Assign Root Privileges
echo "Creating a new user: $NEW_USER"
sudo adduser $NEW_USER --gecos "" --disabled-password
echo "$NEW_USER:$NEW_USER_PASSWORD" | sudo chpasswd
echo "Adding $NEW_USER to sudo group..."
sudo usermod -aG sudo $NEW_USER

# Configure SSH Warning Banner
echo "Setting up SSH warning banner..."
sudo tee /etc/issue.net > /dev/null <<EOF
###############################################################
#                    Authorized access only!                  #
# Disconnect IMMEDIATELY if you are not an authorized user!!! #
#         All actions Will be monitored and recorded          #
###############################################################
EOF

echo "Updating sshd configuration..."
sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOF
Banner /etc/issue.net
PubkeyAuthentication yes
EOF
sudo systemctl restart sshd

# Set Time Zone
echo "Setting timezone to $TIMEZONE..."
sudo timedatectl set-timezone $TIMEZONE
timedatectl

# Set and Check New Hostname
echo "Setting hostname to '$HOSTNAME'..."
sudo hostnamectl set-hostname $HOSTNAME
hostnamectl

# Check Swap
echo "Checking swap space..."
swapon -s

# Configure Email Notifications for Updates
echo "Installing mailutils for email notifications..."
sudo apt install -y -qq mailutils

# Test email
echo "Sending test email to $TEST_EMAIL..."
echo "$MESSAGE" | mail -s "$SUBJECT" $TEST_EMAIL

# Enable Unattended Upgrades
echo "Installing and configuring unattended-upgrades..."
sudo apt install -y -qq unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Configure unattended-upgrades to send update notifications
echo "Setting up unattended-upgrades email notifications..."
sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Mail "$EMAIL";
Unattended-Upgrade::MailReport "on-change";
EOF

# Check Unattended-Upgrades Timer
echo "Listing timers for unattended-upgrades..."
systemctl list-timers apt-daily.timer

# Display System IP Address
echo "System IP address:"
hostname -I

# Halt before reboot
read -p "Setup complete. Do you want to reboot the system now? (y/n): " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" == "y" || "$REBOOT_CONFIRM" == "Y" ]]; then
  echo "Rebooting system..."
  sudo systemctl reboot
else
  echo "Reboot canceled. You may reboot the system manually when ready."
fi
