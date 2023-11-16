#!/bin/bash

# Update the system
apt-get update

# Install Samba
apt-get install samba -y

# Stop and disable netbois server
systemctl stop nmbd.service
systemctl disable nmbd.service

# Make a copy of smb.conf 
mv /etc/samba/smb.conf /etc/samba/smb.conf.orig
touch /etc/samba/smb.conf

# Create system users
adduser --home /pool/home/brandon --no-create-home --shell /usr/sbin/nologin --ingroup sambashare brandon
adduser --home /pool/home/deb --no-create-home --shell /usr/sbin/nologin --ingroup sambashare deb
adduser --home /pool/media/ --no-create-home --shell /usr/sbin/nologin --ingroup sambashare admin

# Create samba share directories
mkdir -p /pool/home/{brandon,deb}

# Set ownership
chown :sambashare /pool/home/
chown :sambashare /pool/media/

chown brandon:sambashare /pool/home/brandon/
chmod 2770 /pool/home/brandon

chown deb:sambashare /pool/home/deb/
chmod 2770 /pool/home/deb

chown admin:sambashare /pool/media/
chmod 2770 /pool/media/

# Add users to the samba server
echo "Add user brandon to samba server ..."
smbpasswd -a brandon
smbpasswd -e brandon

echo "Adding user deb to samba server ..."
smbpasswd -a deb
smbpasswd -e deb

echo "Adding admin user to samba server ..."
smbpasswd -a admin
smbpasswd -e admin

echo " Creating admins group ..."
groupadd admins
usermod -G admins admin

echo " Writing out new smb.conf to /etc/samba/smb.conf"
cat << EOF > /etc/samba/smb.conf
[global]
        server string = samba_server
        server role = standalone server
        interfaces = lo wlan0
        bind interfaces only = yes
        disable netbios = yes
        smb ports = 445
        log file = /var/log/samba/smb.log
        max log size = 10000

[brandon]
        path = /pool/home/brandon
        browseable = no
        read only = no
        force create mode = 0660
        force directory mode = 2770
        valid users = brandon @admins

[deb]
        path = /pool/home/deb
        browseable = no
        read only = no
        force create mode = 0660
        force directory mode = 2770
        valid users = deb @admins

[media]
        path = /pool/media/
        browseable = yes
        read only = no
        force create mode = 0660
        force directory mode = 2770
        guest ok = yes
        guest only = yes
EOF

echo "Restarting samba service ..."
systemctl restart smbd.service
