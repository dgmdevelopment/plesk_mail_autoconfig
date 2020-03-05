#!/bin/bash
# Deploy mail autoconfig for Plesk
# Support for Thunderbird autoconfig, Outlook autodiscover & Apple config generator


## Settings

# These will be visible inside your config files
companyname="PromoteSource"
companylowercasename="promotesource"
companyurl="promotesource.com"
docurl="#"
hostname="$(hostname)"

# Git Platform - github and gitlab are supported
gitplatform="github"

# When forking this repo, you can set your own git info
gitlaburl=""
githuburl="https://raw.githubusercontent.com"
gituser="pub"
gitrepo="Plesk_MailAutoconfig"
gitbranch="master"

## Edit with care or don't
if [ ${gitplatform} = gitlab ]; then
	gitrawfullurl="${gitlaburl}/${gituser}/${gitrepo}/raw/${gitbranch}"
elif [ ${gitplatform} = github ]; then
	gitrawfullurl="${githuburl}/${gituser}/${gitrepo}/${gitbranch}"
else
	fn_logecho "[ Warning ] Selected git platform ${gitplatform} not supported."
	exit
fi
## Edit with care or don't

# Hosting directory
# The place where we host our configuration files
defaulthostingdir="/var/www/vhosts/default/htdocs"

# Thunderbird autoconfig paths
autoconfigpath="${defaulthostingdir}/mail"
autoconfigpathfile="${autoconfigpath}/config-v1.1.xml"

# Outlook autodiscover paths
autodiscoverpath="${defaulthostingdir}/mail"
autodiscoverpathfile="${autodiscoverpath}/autodiscover.xml"
autodiscoverpathfilealt="${autodiscoverpath}/Autodiscover.xml"
autodiscoverhtaccess="${autodiscoverpath}/.htaccess"

# Apple configurator paths
applepath="${defaulthostingdir}/mail"
applewebpagepath="${applepath}/apple.xml"
appleformenpath="${applepath}/apple_en.html"
applemobileconfpathfile="${applepath}/apple.mobileconfig"
appleweblogo="logo.png"
appleweblogourl="${gitrawfullurl}/${appleweblogo}"

# URLs used for tests
autoconfigurl="http://autoconfig.${hostname}/mail/config-v1.1.xml"
autodiscoverurl="https://${hostname}/autodiscover/autodiscover.xml"
autodiscoverurlalt="https://${hostname}/Autodiscover/Autodiscover.xml"
appleconfigurl="http://${hostname}/apple"

##############
### Script ###
##############

# Misc Vars
selfname="Mail Autoconfig"

# Download bash API
if [ ! -f "ultimate-bash-api.sh" ]; then
	wget https://raw.githubusercontent.com/UltimateByte/ultimate-bash-api/master/ultimate-bash-api.sh
	chmod +x ultimate-bash-api.sh
fi
source ultimate-bash-api.sh

fn_logecho "#############################"
fn_logecho "### Plesk Mail Autoconfig ###"
fn_logecho "#############################"
echo ""
sleep 1.5

# Detect if apache is named apache2 or httpd
fn_logecho "[ INFO ] Detecting if Apache is named apache2 or httpd"
sleep 1
if [ -d "/etc/httpd/conf.d" ]&&[ -d "/etc/apache2/conf-enabled" ]; then	
	fn_logecho "[ ERROR ] Both httpd and apache2 dirs were found in /etc"
	exit 1
elif [ -d "/etc/httpd/conf.d/" ]&&[ ! -d "/etc/apache2/conf-enabled" ]; then
	fn_logecho "[ INFO ] Detected httpd, hello RedHat based system"
	apacheautodiscoverconf="/etc/httpd/conf.d/autodiscover.conf"
	apacheservicename="httpd"
elif [ ! -d "/etc/httpd/conf.d" ]&&[ -d "/etc/apache2/conf-enabled" ]; then
	fn_logecho "[ INFO ] Detected apache2, hello Debian based system"
	apacheautodiscoverconf="/etc/apache2/conf-enabled/autodiscover.conf"
	apacheservicename="apache2"
else
	fn_logecho "[ ERROR ] No apache conf.d in /etc/httpd or conf-enabled in /etc/apache2 were found"
	exit 1
fi

fn_logecho "[ INFO ] Creating autoconfig config path if needed"
echo ""
sleep 1

# Files and directories creation
if [ ! -d "${autoconfigpath}" ]; then
	fn_logecho "[ ... ] Creating autoconfig config path"
	fn_logecho "${autoconfigpath}"
	mkdir -p "${autoconfigpath}"
fi

if [ ! -f "${autoconfigpathfile}" ]; then
	fn_logecho "[ ... ] Creating autoconfig config file"
	fn_logecho "${autoconfigpathfile}"
	touch "${autoconfigpathfile}"
fi

if [ ! -d "${autodiscoverpath}" ]; then
	fn_logecho "[ ... ] Creating autodiscover config path"
	fn_logecho "${autodiscoverpath}"
	mkdir -p "${autodiscoverpath}"
fi

if [ ! -f "${autodiscoverpathfile}" ]; then
	fn_logecho "[ ... ] Creating autodiscover config file"
	fn_logecho "${autodiscoverpathfile}"
	touch "${autodiscoverpathfile}"
fi

if [ ! -L "${autodiscoverpathfilealt}" ]; then
	fn_logecho "[ ... ] Symlinking autodiscover alternative config file"
	fn_logecho "${autodiscoverpathfile} -> ${autodiscoverpathfilealt}"
	ln -s "${autodiscoverpathfile}" "${autodiscoverpathfilealt}"
fi

if [ ! -d "${applepath}" ]; then
	fn_logecho "[ INFO ] Creating Apple mail configurator directory"
	fn_logecho "${applepath}"
	mkdir -p "${applepath}"
fi

if [ ! -f "${applewebpagepath}" ]; then
	fn_logecho "[INFO] Creating Apple web page"
	fn_logecho "${applewebpagepath}"
	touch "${applewebpagepath}"
fi

if [ ! -f "${appleformenpath}" ]; then
	fn_logecho "[INFO] Creating Apple english form"
	fn_logecho "${appleformenpath}"
	touch "${appleformenpath}"
fi

if [ ! -f "${applemobileconfpathfile}" ]; then
	fn_logecho "[ INFO ] Creating Apple mobileconfig file"
	fn_logecho "${applemobileconfpathfile}"
	touch "${applemobileconfpathfile}"
fi

if [ ! -f "${autodiscoverhtaccess}" ]; then
	fn_logecho "[ INFO ] Creating autodiscover .htaccess file"
	fn_logecho "${autodiscoverhtaccess}"
	touch "${autodiscoverhtaccess}"
fi

if [ ! -f "${apacheautodiscoverconf}" ]; then
	fn_logecho "[ INFO ] Creating autodiscover Apache configuration file"
	fn_logecho "${apacheautodiscoverconf}"
	touch "${apacheautodiscoverconf}"
fi

## Thunderbird autoconfig
echo ""
fn_logecho "[ INFO ] Writing Thunderbird autoconfig config file"
sleep 1
echo ""
curl "${gitrawfullurl}/config-v1.1.xml" > "${autoconfigpathfile}"

# Replace values with settings
fn_logecho "[ ... ] Populating Thunderbird autoconfig file"
sleep 0.5
sed -i -e "s/HOSTNAME/${hostname}/g" "${autoconfigpathfile}"
sed -i -e "s/COMPANYURL/${companyurl}/g" "${autoconfigpathfile}"
sed -i -e "s@DOCURL@${docurl}@g" "${autoconfigpathfile}"

# DNS for autoconfig
fn_logecho "[ INFO ] Correcting default DNS zone for Thunderbird autoconfig: adding cname autoconfig to ${hostname}"
echo ""
sleep 1
/usr/local/psa/bin/server_dns --add -cname autoconfig -canonical "${hostname}"

fn_logecho "[ ... ] Adding DNS entry for every website for Thunderbird autoconfig"
echo ""
sleep 1
for i in `mysql -uadmin -p\`cat /etc/psa/.psa.shadow\` psa -Ns -e "select name from domains"`; do 
	/usr/local/psa/bin/dns --add "$i" -cname autoconfig -canonical "${hostname}"
	fn_logecho "Adding cname: autoconfig.$i - ${hostname}"
done

## Outlook autodiscover
echo ""
fn_logecho "[ INFO ] Writing Outlook autodiscover file"
sleep 1
curl "${gitrawfullurl}/autodiscover.xml" > "${autodiscoverpathfile}"

# Outlook settings
fn_logecho "[ ... ] Populating Outlook autodiscover file"
sleep 0.5
sed -i -e "s/HOSTNAME/${hostname}/g" "${autodiscoverpathfile}"
sed -i -e "s/COMPANYNAME/${companyname}/g" "${autodiscoverpathfile}"

## Apple config
echo ""
fn_logecho "[ INFO ] Writing Apple config files"
echo ""
sleep 0.5
curl "${gitrawfullurl}/apple.xml" > "${applewebpagepath}"
curl "${gitrawfullurl}/apple_en.html" > "${appleformenpath}"
curl "${gitrawfullurl}/apple.mobileconfig" > "${applemobileconfpathfile}"

# Apple web page Logo
fn_logecho "[ ... ] Downloading ${appleweblogo} logo for Apple web page"
sleep 0.5
wget -O "${applepath}/${appleweblogo}" "${appleweblogourl}"
# Apple Settings
fn_logecho "[ ... ] Populating Apple config files"
sleep 0.5
sed -i -e "s/APPLELOGO/${appleweblogo}/g" "${appleformenpath}"
sed -i -e "s/COMPANYNAME/${companyname}/g" "${appleformenpath}"
sed -i -e "s/HOSTNAME/${hostname}/g" "${applemobileconfpathfile}"
sed -i -e "s/COMPANYLOWERCASENAME/${companylowercasename}/g" "${applemobileconfpathfile}"

## .htaccess config
echo ""
fn_logecho "[ INFO ] Writing htaccess file"
sleep 0.5
echo "AddHandler php-script .php .xml
RewriteEngine on
RewriteCond %{REQUEST_URI} !apple.xml
RewriteCond %{REQUEST_URI} !${appleweblogo}
RewriteCond %{REQUEST_URI} apple
RewriteRule .* /apple/apple.xml [R]" > "${autodiscoverhtaccess}"

## Apache aliases config
echo ""
fn_logecho "[ INFO ] Writing autodiscover Apache configuration file"
sleep 0.5
echo "Alias /autodiscover \"${autodiscoverpath}\"
Alias /Autodiscover \"${autodiscoverpath}\"
Alias /apple \"${applepath}\"" > "${apacheautodiscoverconf}"

echo ""
fn_logecho "[ INFO ] Restarting Apache"
service ${apacheservicename} restart

## Testing

fn_logecho "#############"
fn_logecho "## Testing ##"
fn_logecho "#############"
echo ""
sleep 1

# Test Thunderbird autoconfig
if [ -n "$(curl "${autoconfigurl}" | grep "<socketType>SSL</socketType>")" ]; then
	fn_logecho "[ OK ] Thunderbird ${autoconfigurl} is accessible"
else
	fn_logecho "[ Warning ] Thunderbird ${autoconfigurl} does not seem to be accessible"
fi
echo ""
sleep 0.5
# Test Outlook autodiscover
if [ -n "$(curl "${autodiscoverurl}" | grep "<DisplayName>${companyname}</DisplayName>")" ]; then
	fn_logecho "[ OK ] Outlook ${autodiscoverurl} is accessible"
else
	fn_logecho "[ Warning ] Outlook ${autodiscoverurl} does not seem to be accessible (or certificate is not valid)"
fi
echo ""
sleep 0.5
# Test Outlook Autodiscover
if [ -n "$(curl "${autodiscoverurlalt}" | grep "<DisplayName>${companyname}</DisplayName>")" ]; then
	fn_logecho "[ OK ] Outlook ${autodiscoverurlalt} is accessible"
else
	fn_logecho "[ Warning ] Outlook ${autodiscoverurlalt} does not seem to be accessible (or certificate is not valid)"
fi
echo ""
sleep 0.5
# Test Apple configurator
if [ -n "$(curl -L "${appleconfigurl}" | grep "<form method=\"post\" action=\"apple.xml\">")" ]; then
	fn_logecho "[ OK ] Apple ${appleconfigurl} is accessible"
else
	fn_logecho "[ Warning ] Apple ${appleconfigurl} does not seem to be accessible"
fi

fn_logecho "[ OK ] Done"