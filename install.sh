# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m' 
NC='\033[0m' # No Color

#----------------------------------------------------------------

# Install bind9 dns server 
echo "${YELLOW}Installing bind9..."
apt update > /home/logs 2> /home/errorLogs
apt install bind9 bind9utils bind9-doc -y > /home/logs 2> /home/errorLogs
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Setting network protocol to ipv4
echo "${YELLOW}Setting network protocol to ipv4..."
cp named /etc/default/
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Restarting bind9
echo "${YELLOW}Restarting bind9..."
systemctl restart bind9
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Setting up forwarders
echo "${YELLOW}Setting forwarders..."
cp named.conf.options /etc/bind/
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Sestarting bind9
echo "${YELLOW}Restarting bind9..."
systemctl restart bind9
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Reading domain name from user
echo "${RED}Enter your Domain name (for eg:- yourwebsite.com )"
read domainName

#----------------------------------------------------------------

# Setting ip Address to variable
ipAddress=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
process_id=$!
wait $process_id

#----------------------------------------------------------------

# Setting Authoritative dns server
echo "${YELLOW}Setting Authoritative dns server..."
echo "//
// Do any local configuration here
//

// Consider adding the 1918 zones here, if they are not used in your
// organization
//include \"/etc/bind/zones.rfc1918\";

zone \"$domainName\" {
        type master;
        file \"/etc/bind/db.$domainName\";
};" > named.conf.local

cp named.conf.local /etc/bind/
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Generating Zone file
echo "${YELLOW}Generating Zone file..."
echo "; BIND reverse data file for empty rfc1918 zone
;
; DO NOT EDIT THIS FILE - it is used for multiple zones.
; Instead, copy it, edit named.conf, and use that copy.
;
\$TTL    86400
@       IN      SOA     ns1.$domainName. root.localhost. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                          86400 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domainName.
ns1     IN      A       $ipAddress
@       IN      MX 10   mail.$domainName.
$domainName.  IN      A       $ipAddress
www     IN      A       $ipAddress
mail    IN      A       $ipAddress
external        IN      A       91.189.88.181" > db.$domainName

cp db.$domainName /etc/bind/
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# restarting bind9
echo "${YELLOW}Restarting bind9..."
systemctl restart bind9
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Installing apache web server
echo "${YELLOW}Installing apache web server..."
apt update > /home/logs 2> /home/errorLogs
apt install apache2 ufw -y > /home/logs 2> /home/errorLogs
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#---------------------------------------------------------

# Allowing apache on ufw
echo "${YELLOW}Allowing apache on ufw..."
ufw allow 'Apache Full' > /home/logs 2> /home/errorLogs
echo "${GREEN}DONE"

#---------------------------------------------------------

# Setting up Virtual Hosting
echo "${YELLOW}Setting up Virtual Hosting..."
mkdir /var/www/$domainName
chown -R www-data.www-data /var/www/$domainName/
chmod 755 /var/www/$domainName/ 
#mkdir /etc/apache2/sites-available/  > /home/logs 2> /home/errorLogs
echo "<VirtualHost *:80>
  ServerName $domainName
  ServerAlias www.$domainName
  DocumentRoot /var/www/$domainName
  ErrorLog /var/log/apache2/$domainName.error.log
  CustomLog /var/log/apache2/$domainName.access.log combined
</VirtualHost>" > $domainName.conf 
cp $domainName.conf /etc/apache2/sites-available/
a2ensite $domainName  > /home/logs 2> /home/errorLogs
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# restarting apache2
echo "${YELLOW}Restarting apache2..."
systemctl restart apache2
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Installing certbot for SSL certificate
echo "${YELLOW}Installing certbot for SSL certificate..."
apt update > /home/logs 2> /home/errorLogs
apt install certbot python3-certbot-apache -y > /home/logs 2> /home/errorLogs
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# Installing SSL certificate
echo "${YELLOW}Installing SSL certificate..."
echo "${RED}Please follow all prompts below..."
certbot -d $domainName
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

##################################################################
# more steps remains
##################################################################

#----------------------------------------------------------------

# Installing PHP and sql-MyAdmin
echo "${YELLOW}Installing PHP and sql-MyAdmin..."
apt update > /home/logs 2> /home/errorLogs
apt install php php-mysql libapache2-mod-php -y > /home/logs 2> /home/errorLogs
process_id=$!
wait $process_id
echo "${GREEN}DONE"

#----------------------------------------------------------------

# restarting apache2
echo "${YELLOW}Restarting apache2..."
systemctl restart apache2
process_id=$!
wait $process_id
echo "${GREEN}DONE"