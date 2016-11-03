#!/bin/bash
NEWT_COLORS=' 
  root=,black
  window=green,green
  border=yellow,yellow
  shadow=red,red
  textbox=black,green
  button=black,green
' \
echo ""
RED='\033[1;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' 
echo""
if (whiptail --title "Installation" --yesno "voulez vous lancer l'installation ?" --yes-button "oui" --no-button "non" 10 60) then
	echo ""
	printf "%b\n" "   ${GREEN}////////////////////////////////////////////////${NC}\n   ${YELLOW}//      Début du programme dinstallation      //${NC}\n   ${RED}////////////////////////////////////////////////${NC}\n"
	echo ""
	echo ""
	printf "%b\n" "${BLUE}     ********************************\n     *   mise à jour du Raspberry   *\n     ********************************${NC}\n"
	echo ""
	apt-get update && apt-get upgrade -y
	echo ""
	echo ""
	printf "%b\n" "${BLUE}     *************************************************\n     *   installation de build, python, git et pip   *\n     *************************************************${NC}\n"
	echo ""
	apt-get install apt-transport-https -y && apt-get install build-essential python-dev python-openssl git python-pip -y
	echo ""
	printf "%b\n" "${BLUE}     ***************************************************\n     *   installation de la librairie python 'ephem'   *\n     ***************************************************${NC}\n"
	echo ""
	pip install ephem 
	echo ""
	printf "%b\n" "${BLUE}     *****************************************************************\n     *   installation des librairies adafruit pour lire les sondes   *\n     *****************************************************************${NC}\n"
	echo ""
	cd /home/pi
	git clone https://github.com/adafruit/Adafruit_Python_DHT.git
	cd Adafruit_Python_DHT
	python setup.py install
	echo ""
	printf "%b\n" "${BLUE}     ********************************************************************\n     *   installation des librairies pour communiquer avec lécran LCD  *\n     ********************************************************************${NC}\n"
	echo ""
	cd /home/pi
	git clone https://github.com/dbrgn/RPLCD
	cd RPLCD
	python setup.py install
	echo ""
	printf "%b\n" "${BLUE}     ************************************************************\n     *   installation de LAMP (linux apache mysql phpmyadmin)   *\n     ************************************************************${NC}\n"
	echo ""
	printf "Vous allez devoir ici ${RED}définir un mot de passe root mysql${NC},\npuis pour ${GREEN}phpmyadmin choisissez apache${NC}\n${RED}définissez un mot de passe pour phpmyadmin${NC} (${YELLOW}mettre le même que mysql cest plus simple${NC})\n"
	echo ""
	echo "appuiez sur entrée pour continuer"
	read a
	apt-get install mysql-server python-mysqldb apache2 php5 libapache2-mod-php5 php5-mysql phpmyadmin shellinabox -y
	echo ""
	printf "%b\n" "${BLUE}     *************************************\n     *   création de la base de donnée   *\n     *************************************${NC}\n"
	echo ""
	read a
	dbname="Terrarium"
	echo""		
    mdproot=$(whiptail --title "Mot de passe root Mysql" --passwordbox "Entrer le mot de passe root mysql :" 10 60 3>&1 1>&2 2>&3) 
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		mysql -uroot -p${mdproot} -e "CREATE DATABASE ${dbname};"    
	else
		echo "Annulé"
	fi
	echo ""
	mysql -uroot -p${mdproot} -e "CREATE DATABASE ${dbname};"
	echo""
	printf "${BLUE} liste des base de donnée de mysql, la base Terrarium doit être présente${NC}\n"
	mysql -uroot -p${mdproot} -e "show databases;"
	echo ""
	loginbdd=$(whiptail --title "Login user mysql" --inputbox "Choisir un non d'utilisateur pour mysql :" 10 60 3>&1 1>&2 2>&3)
	exitstatus2=$?
	if [ $exitstatus2 = 1 ]; then 
		echo "Annulé"
	fi
	echo ""	
	mdpbdd=$(whiptail --title "Mot de passe user Mysql" --passwordbox "Choisir un mot de passe pour cet utilisateur :" 10 60 3>&1 1>&2 2>&3) 
	exitstatus3=$?
	if [ $exitstatus3 = 0 ]; then
		mysql -hlocalhost -uroot -p${mdproot} -e "CREATE USER ${loginbdd}@localhost IDENTIFIED BY '${mdpbdd}';"
		mysql -hlocalhost -uroot -p${mdproot} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${loginbdd}'@'localhost';"
		mysql -hlocalhost -uroot -p${mdproot} -e "FLUSH PRIVILEGES;"
	else
		echo "Annulé"
	fi
	echo ""
	echo "Création du nouvel utilisateur et donne les droits sur la base de donnée Terrarium"
	echo ""
	mysql -hlocalhost -uroot -p${mdproot} -e "CREATE USER ${loginbdd}@localhost IDENTIFIED BY '${mdpbdd}';"
	mysql -hlocalhost -uroot -p${mdproot} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${loginbdd}'@'localhost';"
	mysql -hlocalhost -uroot -p${mdproot} -e "FLUSH PRIVILEGES;"
	echo ""	
	echo "On crée la table capteurdata"
	mysql -u${loginbdd} -p${mdpbdd} -hlocalhost -D${dbname} -e "CREATE TABLE capteurdata (dateandtime DATETIME, tempF DOUBLE, humF DOUBLE, tempC DOUBLE, humC DOUBLE);"
	echo ""						   
	echo "on créer la table config"
	echo ""
	mysql -u${loginbdd} -p${mdpbdd} -hlocalhost -D${dbname} -e "CREATE TABLE config (dateetheure DATETIME, loginadmin VARCHAR(32), mdpadmin VARCHAR(32), longitude FLOAT, latitude FLOAT, altitude INT, limitebasse INT, limitehaute INT, jour INT, nuit INT, warmpi INT, envoyeur VARCHAR(32), mdpenvoyeur VARCHAR(32), receveur VARCHAR(32), ip VARCHAR(32), Heure_ete_hiver INT);"
	echo ""
	echo "on redémarre mysql "
	echo ""
	/etc/init.d/mysql restart
	echo ""
	printf "%b\n" "${BLUE}   ****************************************************\n   *   téléchargement et installation de terraspiV2   *\n   ****************************************************${NC}\n"
	echo ""
	cd /var/www/html/
	rm index.html
	rm -R terraspi	
	chown -R www-data:pi /var/www/html/
	chmod -R 770 /var/www/html/
	echo ""
	cd /home/pi
	git clone https://github.com/weedmanu/terraspiV2.git
	cd /home/pi/terraspiV2
	mv terraspi -t /var/www/html/
	chown -R www-data:pi /var/www/html/
	chmod -R 770 /var/www/html/
	cd /var/www/html/terraspi/
	cp install.sh -t /var/www/html/terraspi/prog/
	cd /var/www/html/terraspi/csv/
	echo ""
	printf "%b\n" "${BLUE}    **************\n    *    MySQL   *\n    **************${NC}\n"
	echo ""
	echo "login mysql"
	echo ""	
	sed -i "s/loginbdd/${loginbdd}/g" bdd.json
	echo "ok"
	echo ""	
	echo "mot de passe mysql"
	echo ""
	sed -i "s/mdpbdd/${mdpbdd}/g" bdd.json
	echo "ok"		
	echo ""
	printf "%b\n" "${BLUE}    ******************\n    *     Admin      *\n    ******************${NC}\n"
	echo ""
	loginadmin=$(whiptail --title "Configuration" --inputbox "Choisir un non d'utilisateur pour la page admin :" 10 60 3>&1 1>&2 2>&3)
	exitstatus4=$?
	if [ $exitstatus4 = 1 ]; then 
		echo "Annulé"
	fi
	mdpbadmin=$(whiptail --title "Configuration" --passwordbox "Choisir un mot de passe pour cet utilisateur :" 10 60 3>&1 1>&2 2>&3) 
	exitstatus5=$?
	if [ $exitstatus5 = 1 ]; then
		echo "Annulé"
	fi
	echo ""	
	printf "%b\n" "${BLUE}    ***************\n    *     IP      *\n    ***************${NC}\n"
	echo ""
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
	ip=$(whiptail --title "Configuration" --inputbox "Quelle est l'adresse ip de votre Raspberry pi ?" 10 60 3>&1 1>&2 2>&3)
	exitstatus6=$?
	if [ $exitstatus6 = 1 ]; then 
		echo "Annulé"
	fi

	until valid_ip $ip
	do
		ip=$(whiptail --title "Configuration" --inputbox "Une adresse ip valide !!! :" 10 60 3>&1 1>&2 2>&3)
		exitstatus7=$?
		if [ $exitstatus7 = 1 ]; then 
			echo "Annulé"
		fi
		
	done
	echo ""	
	echo ""
	dateetheure=$(date +%Y%m%d%H%M%S)
	echo ""
	echo ""
	mysql -uroot -p${mdproot} -hlocalhost -D${dbname} -e "INSERT INTO config (dateetheure, loginadmin, mdpadmin, ip) VALUES ( '$dateetheure', '$loginadmin', '$mdpadmin', '$ip' )";
	echo ""
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
	python /var/www/html/terraspi/prog/lcd.py &
	echo ""
	printf "%b\n" "${GREEN}           ********************************\n          ********************************${NC}\n${YELLOW}           **    FIN de l installation   **${NC}\n${RED}           ********************************\n           ********************************${NC}\n"
	echo ""
	echo "ensuite :"
	printf "%b\n" "${BLUE}"
	printf "           http://${ip}:4200"
	printf "%b\n" "${NC}"
	printf "%b\n" "${YELLOW}"
	echo " Ouvrer ce lien dans votre navigateur , il va passer en https , il faut ajouter une execption de sécuriter en cliquant sur avancé "
	echo " Cocher conserver de façon permanante, et vous tomberez sur le terminal du pi. fermer la page. "
	printf "%b\n" "${NC}"
	echo "Appuyer sur la touche entrée pour continuer"
	read a
	printf "%b\n" "${YELLOW}"
	echo "Ouvrer ce lien dans votre navigateur internet et entrer vos identifiant pour la page admin et régler les derniers paramètres du terrarium"
	printf "%b\n" "${BLUE}"
	echo "   http://${ip}/terraspi/admin/"
	printf "%b\n" "${NC}"
	echo ""
	printf "%b\n" "${GREEN}powered${NC}${YELLOW} by ${NC}${LRED}weedmanu${NC}\n"
else
	whiptail --title "Installation" --msgbox "Installation annulée !!!" 10 60
fi
exit
