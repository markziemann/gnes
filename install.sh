#!/bin/bash
#GNES installer by mark ziemann sept 2016
#mark.ziemann@gmail.com

##run this script as follows
#chmod +x install.sh
#sudo bash install.sh

##########################################################
echo "1st installing dependancies"
##########################################################
#php via ppa repo
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update
sudo apt-get install php
sudo apt-get install apache2
sudo apt-get install gnumeric
sudo apt-get install num-utils
sudo apt-get install enscript
sudo apt-get install ghostscript
sudo apt-get install mailutils

##########################################################
echo "installing html, php & sh script"
##########################################################
#put html
sudo cp gnes.html gnes.php /var/www/html
#put php
sudo chmod +x /var/www/html/gnes.php
#put sh script
sudo cp -r code /var/www/
sudo chmod +x /var/www/code/scan_uploaded_files.sh
sudo ln -s /var/www/code /var/www/html/

#setup upload directory
sudo mkdir -p /var/www/upload/
sudo chmod -R 755 /var/www/upload/

#create tmp directory for sscnvert
sudo mkdir -p /var/www/.local/share
sudo chown -R www-data:www-data /var/www


echo "The php config file (/etc/php/7.0/apache2/php.ini) will need to be modified to allow \
larger files to upload as the default is 2M. Look for the following line in the file:
upload_max_filesize = 2M
And change it to accommodate files up to 100MB a follows:
upload_max_filesize = 100M
"

##########################################################
echo "installing cleanup old pdf files script in crontab"
##########################################################
echo 'rm `find /var/www/code/*pdf -type f -mmin +60`' > /var/www/code/cleanup_pdf.sh
chmod +x /var/www/code/cleanup_pdf.sh
crontab -l > /tmp/my-crontab
echo '30 2 * * * bash /var/www/code/cleanup_pdf.sh' >> /tmp/my-crontab
sudo crontab /tmp/my-crontab
