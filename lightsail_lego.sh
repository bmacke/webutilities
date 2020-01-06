!/bin/bash
# this script is for use with servers running apache2
# install lego client for use with letsencrypt on amazon lightsail with bitnami
# set up crontab to renew certs every 90 days
# version 3.a 11-24-2019

cd /tmp
curl -Ls https://api.github.com/repos/xenolf/lego/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4 | wget -i -
tar xf lego*
sudo mkdir -p /opt/bitnami/letsencrypt
sudo mv lego /opt/bitnami/letsencrypt/lego

#stop services
sudo /opt/bitnami/ctlscript.sh stop

#get domain name to use example.com
echo "adding a domain name please use FQDN ..."
echo "FQDN?"
read fqdn

#get email name to use name@example.com
echo "adding a email ..."
echo "emailaddress?"
read emailaddress

sudo /opt/bitnami/letsencrypt/lego --tls --accept-tos --email="$emailaddress" --domains="$fqdn" --domains="www.$fqdn" --path="/opt/bitnami/letsencrypt" run

#backup the old server.crt server.key server.csr files
sudo mv /opt/bitnami/apache2/conf/server.crt /opt/bitnami/apache2/conf/server.crt.old
sudo mv /opt/bitnami/apache2/conf/server.key /opt/bitnami/apache2/conf/server.key.old
sudo mv /opt/bitnami/apache2/conf/server.csr /opt/bitnami/apache2/conf/server.csr.old

#link new letsencrypt certs to server.key and server.cert
sudo ln -sf /opt/bitnami/letsencrypt/certificates/$fqdn.key /opt/bitnami/apache2/conf/server.key
sudo ln -sf /opt/bitnami/letsencrypt/certificates/$fqdn.crt /opt/bitnami/apache2/conf/server.crt

#set permissions on server files
sudo chown root:root /opt/bitnami/apache2/conf/server*
sudo chmod 600 /opt/bitnami/apache2/conf/server*

# start services
sudo /opt/bitnami/ctlscript.sh start

# Set up the script for cron
sudo touch /home/bitnami/renew-cert.sh
renewscript=/opt/bitnami/letsencrypt/renew-cert.sh
echo 'sudo /opt/bitnami/letsencrypt/lego --tls --accept-tos --email="'"$emailaddress"'" --domains="'"$fqdn"'" --domains="www.'"$fqdn"'" --path="/opt/bitnami/letsencrypt"' renew >> /home/bitnami/renew-cert.sh
chmod 755 /home/bitnami/renew-cert.sh

#Modify crontab
line="0 0 1 * * /home/bitnami/renew-cert.sh 2> /dev/null"
(crontab -u bitnami -l; echo "$line") | crontab -u bitnami -
