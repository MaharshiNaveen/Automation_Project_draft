#version 0.2
#.....initializing time, service name and bucket name.....#
timestamp=$(date '+%d%m%Y-%H%M%S')
service=apache2
myname=pasupuleti
s3_bucket=upgrad-pasupuleti

#.....initializing time service name and bucket name.....#
if [ -e /etc/cron.d/automation ]
then
crontab /etc/cron.d/automation
echo "automation file exists"
else
touch /etc/cron.d/automation
echo "SHELL=/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin
#cron job to perform automation script
* * * * *  root /root/Automation_Project/automation.sh
" >> /etc/cron.d/automation
crontab /etc/cron.d/automation
fi
#.....Bookkeeping inventory creation.....#
if [ -e /var/www/html/inventory.html ]
        then
        echo "Inventory exists"
        else
        touch /var/www/html/inventory.html
        cd /var/www/html/
        echo "<b>Log Type &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Date Created &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Type &nbsp;&nbsp; Size &nbsp</b><br>" >> inventory.html
fi

function automate {
#.....directing to log archive location....#
cd /var/log/apache2/
#.....installing aws-cli if not there....#
if (( ! ( $(which aws | wc -l) > 0 )))
then
        sudo apt update
                sudo apt install awscli
fi

#.....creating needed folders.....#
if [[ ! -d "/tmp/apache2_log_bkp" ]]
then
    mkdir /tmp/apache2_log_bkp
fi

#.....archiving the logs and emptying them....#
tar -cvf /tmp/apache2_log_bkp/${myname}-httpd-logs-${timestamp}.tar access.log error.log other_vhosts_access.log && true > access.log && true > error.log
echo "$service logs are created at $timestamp"
#.....directing to log archive location....#
cd /tmp/apache2_log_bkp
#.....uploading to s3 bucket named upgrad-pasupuleti.....#
aws s3 \
cp  ${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}

#.....bookkeeping the log archive.....#
cd /var/www/html/
filesize=$(ls -lh /tmp/apache2_log_bkp/${myname}-httpd-logs-${timestamp}.tar | awk '{print  $5}')
echo "<p >httpd-logs &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ${timestamp} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; tar &nbsp;&nbsp; ${filesize} &nbsp;&nbsp </p><br>" >> inventory.html

}


#.....condition which checks the service is installed or not....#
if [ ! -e "/etc/init.d/$service" ]; then
#......starting the apache server if not started......#
/etc/init.d/$service start
echo "$service is started!"
fi

#.....condition which checks the service is running or not
if (( ! $(ps -ef | grep $service | wc -l) > 0 ))
then
sudo apt update
sudo apt install $service
echo "installing $service"
/etc/init.d/$service start
fi

if [ -e "/etc/init.d/$service" ] && (($(ps -ef | grep $service | wc -l) > 0 ))
then
automate
else
echo "not automating"
fi

