# Install Fail2ban
echo "Installing fail2ban..."
sudo apt install -y fail2ban

# Configure Fail2ban for SSH Protection
echo "Configuring fail2ban for SSH protection..."
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
EOF
sudo systemctl restart fail2ban
