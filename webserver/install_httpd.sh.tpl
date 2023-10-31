#!/bin/bash

# Install required packages
yum -y update
yum -y install httpd

private_ip=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
public_ip=`curl -s http://169.254.169.254/latest/meta-data/public-ipv4`
instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
instance_type=`curl -s http://169.254.169.254/latest/meta-data/instance-type`

echo "<h1>Welcome to ACS730 - ${prefix}'s Lab!</h1>" > /var/www/html/index.html
echo "<p>My public IP is: <strong>$public_ip</strong></p>" >> /var/www/html/index.html
echo "<p>My private IP is: <strong>$private_ip</strong></p>" >> /var/www/html/index.html
echo "<p>Instance ID: <strong>$instance_id</strong></p>" >> /var/www/html/index.html
echo "<p>Instance Type: <strong>$instance_type</strong></p>" >> /var/www/html/index.html
echo "<p>Environment: <font color='red'>${env}</font></p>" >> /var/www/html/index.html
echo "<p><em>Built by Terraform!</em></p>" >> /var/www/html/index.html

HOUR=$(date +"%H")
if [ $HOUR -lt 12  -a $HOUR -ge 0 ]
then
    MESSAGE="Good morning!"
elif [ $HOUR -lt 17 -a $HOUR -ge 12 ]
then
    MESSAGE="Good afternoon!"
else
    MESSAGE="Good evening!"
fi
echo "<p>$MESSAGE Hope you are having a great day!</p>" >> /var/www/html/index.html

sudo systemctl start httpd
sudo systemctl enable httpd
