#version 0.1
#.....initializing time, service name and bucket name.....#
timestamp=$(date '+%d%m%Y-%H%M%S')
service=apache2
myname=pasupuleti
s3_bucket=upgrad-pasupuleti

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


