# Install Telegraf for Monitoring
echo "Installing Telegraf for system monitoring..."
sudo apt install -y curl gpg telegraf

# Configure Telegraf Plugins
echo "Configuring Telegraf plugins..."
sudo tee -a /etc/telegraf/telegraf.conf > /dev/null <<EOF

[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false

[[inputs.temp]]

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.mem]]

EOF
sudo systemctl restart telegraf
