#!/bin/bash
if (whiptail --title "installation" --yesno "voulez vous lancer l'installation ?" --yes-button "oui" --no-button "non" 10 60 0 3>&1 1>&2 2>&3) then
    {	
	echo "0"; sleep 1
	apt-get update && apt-get upgrade -y; sleep 1
	echo "20"; sleep 1
	apt-get install apt-transport-https -y && apt-get install build-essential python-dev python-openssl git python-pip -y; sleep 1
	echo "40";sleep 1
	pip install ephem 
	echo "60"; sleep 1
	cd /home/pi
	git clone https://github.com/adafruit/Adafruit_Python_DHT.git
	cd Adafruit_Python_DHT
	python setup.py install; sleep 1 
	echo "70"; sleep 1
	cd /home/pi
	git clone https://github.com/dbrgn/RPLCD
	cd RPLCD
	python setup.py install; sleep 1
	echo "80" ; sleep 1
	apt-get install mysql-server python-mysqldb apache2 php5 libapache2-mod-php5 php5-mysql phpmyadmin shellinabox -y; sleep 1
	echo "100"
	} | whiptail --gauge "Veuillez patienter ..." 10 60
else
	whiptail --title "Installation" --msgbox "Installation annulée !!!" 10 60 0
fi
whiptail --title "Installation" --msgbox "Création de la base de donnée" 10 60 0
dbname="Terrarium"
mdproot=$(whiptail --title "mot de passe root Mysql" --passwordbox "Entrer le mot de passe root mysql :" 10 60 0 3>&1 1>&2 2>&3) 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    mysql -uroot -p${mdproot} -e "CREATE DATABASE ${dbname};"    
else
    echo "Annulé"
fi
loginbdd=$(whiptail --title "login user mysql" --inputbox "choisir un non d'utilisateur pour mysql :" 10 60 0 3>&1 1>&2 2>&3)
exitstatus2=$?
if [ $exitstatus2 = 1 ]; then 
	echo "Annulé"
fi
mdpbdd=$(whiptail --title "mot de passe user Mysql" --passwordbox "et son mot de passe :" 10 60 0 3>&1 1>&2 2>&3) 
exitstatus3=$?
if [ $exitstatus3 = 0 ]; then
	mysql -hlocalhost -uroot -p${mdproot} -e "CREATE USER ${loginbdd}@localhost IDENTIFIED BY '${mdpbdd}';"
	mysql -hlocalhost -uroot -p${mdproot} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${loginbdd}'@'localhost';"
	mysql -hlocalhost -uroot -p${mdproot} -e "FLUSH PRIVILEGES;"
else
	echo "Annulé"
fi
sleep 1
mysql -u${loginbdd} -p${mdpbdd} -hlocalhost -D${dbname} -e "CREATE TABLE capteurdata (dateandtime DATETIME, tempF DOUBLE, humF DOUBLE, tempC DOUBLE, humC DOUBLE);"
sleep 1
mysql -u${loginbdd} -p${mdpbdd} -hlocalhost -D${dbname} -e "CREATE TABLE config (dateetheure DATETIME, loginadmin VARCHAR(32), mdpadmin VARCHAR(32), longitude FLOAT, latitude FLOAT, altitude INT, limitebasse INT, limitehaute INT, jour INT, nuit INT, warmpi INT, envoyeur VARCHAR(32), mdpenvoyeur VARCHAR(32), receveur VARCHAR(32), ip VARCHAR(32));"
sleep 1
/etc/init.d/mysql restart
sleep 1
whiptail --title "Installation terraspiV2" --msgbox "téléchargement et installation de terraspiV2" 10 60 0
cd /var/www/html/
rm index.html
rm -R terraspi
chown -R www-data:pi /var/www/html/
chmod -R 770 /var/www/html/
cd /home/pi
git clone https://github.com/weedmanu/terraspiV2.git
cd /home/pi/terraspiV2
mv terraspi -t /var/www/html/
chown -R www-data:pi /var/www/html/
chmod -R 770 /var/www/html/
cd /var/www/html/terraspi/
cp install.sh -t /var/www/html/terraspi/prog/
cd /var/www/html/terraspi/csv/	
whiptail --title "Configuration" --msgbox "Configuration initial" 10 60 0
loginadmin=$(whiptail --title "Configuration" --inputbox "choisir un non d'utilisateur la page admin :" 10 60 3>&1 1>&2 2>&3)
exitstatus4=$?
if [ $exitstatus4 = 1 ]; then 
	echo "Annulé"
fi
mdpbadmin=$(whiptail --title "Configuration" --passwordbox "et son mot de passe :" 10 60 3>&1 1>&2 2>&3) 
exitstatus5=$?
if [ $exitstatus5 = 1 ]; then
	echo "Annulé"
fi
function valid_ip()
	{
		local  ip=$1
		local  stat=1

		if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
			OIFS=$IFS
			IFS='.'
			ip=($ip)
			IFS=$OIFS
			[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
				&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
			stat=$?
		fi
		return $stat
		
	}
ip=$(whiptail --title "Configuration" --inputbox "Quelle est l'ip du Raspberry pi :" 10 60 3>&1 1>&2 2>&3)

until valid_ip $ip
do
	ip=$(whiptail --title "Configuration" --inputbox "Une adresse ip valide !!! :" 10 60 3>&1 1>&2 2>&3)
	
done	
dateetheure=$(date +%Y%m%d%H%M%S)
sleep 1
mysql -uroot -p${mdproot} -hlocalhost -D${dbname} -e "INSERT INTO config (dateetheure, loginadmin, mdpadmin, ip) VALUES ( '$dateetheure', '$loginadmin', '$mdpadmin', '$ip' )";
sleep 1
cd /var/www/html/terraspi/
rm install.sh
cd /home/pi/
rm -R terraspiV2
crontab -upi -l > tachecron
echo "* * * * * python /var/www/html//terraspi/prog/terra.py > /dev/null 2>&1" >> tachecron
echo "*/15 * * * * python /var/www/html/terraspi/prog/bdd.py > /dev/null 2>&1" >> tachecron
crontab -upi tachecron
rm tachecron
cp /etc/rc.local /home/pi/test
sed -i '$d' test
echo "python /var/www/html//terraspi/prog/lcd.py" >> test
echo "" >> test
echo "exit 0" >> test
mv test /etc/rc.local
rm test
python -upi /var/www/html/terraspi/prog/lcd.py &
whiptail --title "shellinabox" --msgbox "ouvrez ce lien : http://${ip}:4200 dans votre navigateur , il va passer en https , il faut ajouter une execption de sécuriter en cliquant sur avancé, cocher conserver de façon permanante, et vous tomber sur le terminal du pi. fermer la page" 10 60 0
whiptail --title "page admin" --msgbox "Accés à lapage admin : http://${ip}/terraspi/admin/ , et finissez le réglage." 10 60 0

exit
