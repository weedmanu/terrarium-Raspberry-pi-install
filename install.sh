#!/bin/bash

# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color
echo""
echo "Voulez-vous démmarer l'installation ? (y/n)"
read ouinon
if [ "$ouinon" = "y" ] || [ "$ouinon" = "Y" ]; then
	echo ""
	echo ""
	printf "%b\n" "   ${GREEN}////////////////////////////////////////////////${NC}\n   ${YELLOW}//     Début du programme d'installation      //${NC}\n   ${RED}////////////////////////////////////////////////${NC}"
	echo ""
	echo ""
	printf "%b\n" "${BLUE}     ********************************\n     *   mise à jour du Raspberry   *\n     ********************************${NC}\n"
	echo ""
	sleep 1
	apt-get update && apt-get upgrade -y
	echo ""
	printf "%b\n" "${BLUE}     *************************************************\n     *   installation de build, python, git et pip   *\n     *************************************************${NC}\n"
	echo ""
	sleep 1
	apt-get install apt-transport-https -y && apt-get install build-essential python-dev python-openssl git python-pip -y
	echo ""
	echo ""
	printf "%b\n" "${BLUE}     ***************************************************\n     *   installation de la librairie python 'ephem'   *\n     ***************************************************${NC}\n"
	echo ""
	sleep 1
	pip install ephem 
	echo ""
	printf "%b\n" "${BLUE}     *****************************************************************\n     *   installation des librairies adafruit pour lire les sondes   *\n     *****************************************************************${NC}\n"
	echo ""
	sleep 1
	cd /home/pi
	git clone https://github.com/adafruit/Adafruit_Python_DHT.git
	cd Adafruit_Python_DHT
	python setup.py install
	echo ""
	printf "%b\n" "${BLUE}     ********************************************************************\n     *   installation des librairies pour communiquer avec l'écran LCD  *\n     ********************************************************************${NC}\n"
	echo ""
	sleep 1
	cd /home/pi
	git clone https://github.com/dbrgn/RPLCD
	cd RPLCD
	python setup.py install
	echo ""
	printf "%b\n" "${BLUE}     ************************************************************\n     *   installation de LAMP (linux apache mysql phpmyadmin)   *\n     ************************************************************${NC}\n"
	echo ""
	printf "Vous allez devoir ici ${LRED}définir un mot de passe root mysql${NC},\npuis pour ${LRED}phpmyadmin choisissez apache${NC}\n${LRED}définissez un mot de passe pour phpmyadmin${NC} (${YELLOW}mettre le même que mysql c'est plus simple${NC})\n"
	echo ""
	echo "appuiez sur une touche pour continuer"
	read a
	apt-get install mysql-server python-mysqldb apache2 php5 libapache2-mod-php5 php5-mysql phpmyadmin shellinabox -y
	echo ""
	printf "%b\n" "${BLUE}     *************************************\n     *   création de la base de donnée   *\n     *************************************${NC}\n"
	echo ""
	sleep 1
	dbname="Terrarium"
	echo""		
	sleep 1
    unset mdproot
	prompt="Entrer le mot de passe root mysql :"
	while IFS= read -p "$prompt" -r -s -n 1 char
	do
		if [[ $char == $'\0' ]]
		then
			break
		fi
		prompt='*'
		mdproot+="$char"
	done
	echo ""
	printf "${BLUE} Création de la base de donnée .....${NC}\n"
	sleep 1
	mysql -uroot -p${mdproot} -e "CREATE DATABASE ${dbname};"
	echo""
	printf "${BLUE} liste des base de donnée de mysql, la base Terrarium doit être présente${NC}\n"
	sleep 1
	mysql -uroot -p${mdproot} -e "show databases;"
	echo ""
	echo "Vous devez définir un nom d'utilisateur :"	
	read loginbdd
	echo ""	
	unset mdpbdd
	prompt2="Définir le mot de passe de cet utilisateur"
	while IFS= read -p "$prompt2" -r -s -n 1 char2
	do
		if [[ $char2 == $'\0' ]]
		then
			break
		fi
		prompt2='*'
		mdpbdd+="$char2"
	done
	echo ""
	printf "${BLUE} Création du nouvel utilisateur et donne les droits sur la base de donnée Terrarium${NC}\n"
	echo ""
	sleep 1
	mysql -hlocalhost -uroot -p${mdproot} -e "CREATE USER ${loginbdd}@localhost IDENTIFIED BY '${mdpbdd}';"
	mysql -hlocalhost -uroot -p${mdproot} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${loginbdd}'@'localhost';"
	mysql -hlocalhost -uroot -p${mdproot} -e "FLUSH PRIVILEGES;"
	echo ""	
	echo "On crée la table capteurdata"
	sleep 1
	mysql -u${loginbdd} -p${mdpbdd} -hlocalhost -D${dbname} -e "CREATE TABLE capteurdata (dateandtime DATETIME, tempF DOUBLE, humF DOUBLE, tempC DOUBLE, humC DOUBLE);"
	echo ""						   
	echo "on créer la table config"
	echo ""
	sleep 1
	mysql -u${loginbdd} -p${mdpbdd} -hlocalhost -D${dbname} -e "CREATE TABLE config (dateetheure DATETIME, loginadmin VARCHAR(32), mdpadmin VARCHAR(32), longitude FLOAT, latitude FLOAT, altitude INT, limitebasse INT, limitehaute INT, jour INT, nuit INT, warmpi INT, envoyeur VARCHAR(32), mdpenvoyeur VARCHAR(32), receveur VARCHAR(32), ip VARCHAR(32), Heure_ete_hiver INT);"
	echo ""
	echo "on redémarre mysql "
	echo ""
	sleep 1
	/etc/init.d/mysql restart
	echo ""
	printf "%b\n" "${BLUE}   ****************************************************\n   *   téléchargement et installation de terraspiV2   *\n   ****************************************************${NC}\n"
	echo ""
	sleep 1
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
	echo ""
	echo "login mysql"
	sleep 1
	echo ""	
	sed -i "s/loginbdd/${loginbdd}/g" bdd.json
	echo "ok"
	echo ""	
	echo "mot de passe mysql"
	sleep 1
	echo ""
	sed -i "s/mdpbdd/${mdpbdd}/g" bdd.json
	echo "ok"		
	echo ""
	printf "%b\n" "${BLUE}    ******************\n    *     Admin      *\n    ******************${NC}\n"
	echo ""
	echo ""
	echo ""
	echo ""
	echo "Entrer un nom d'utilisteur pour la page web admin :"
	echo ""
	echo "taper entrée pour valider"
	read loginadmin
	echo ""
	echo "définir un mot de passe pour cet utilisateur :"
	echo ""
	echo "taper entrée pour valider"
	read mdpadmin
	echo ""	
	printf "%b\n" "${BLUE}    ***************\n    *     IP      *\n    ***************${NC}\n"
	echo ""
	echo "quelle est l'ip de votre Raspberry pi :"
	echo ""
	echo "taper entrée pour valider"
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
	read -p "ton ip ?" ip

	until valid_ip $ip
	do
		read -p  "ton ip valide !!! : " ip;
		
	done
	echo ""	
	echo ""
	dateetheure=$(date +%Y%m%d%H%M%S)
	echo ""
	echo ""
	mysql -uroot -p${mdproot} -hlocalhost -D${dbname} -e "INSERT INTO config (dateetheure, loginadmin, mdpadmin, ip) VALUES ( '$dateetheure', '$loginadmin', '$mdpadmin', '$ip' )";
	echo ""	
	echo ""
	echo ""
	echo "Et je dirais même plus , "
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
	python /var/www/html/terraspi/prog/lcd.py &
	echo ""
	printf "%b\n" "${GREEN}           ********************************\n           ********************************${NC}\n${YELLOW}           **    FIN de l' installation   **${NC}\n${RED}           ********************************\n           ********************************${NC}\n"
	echo ""
	sleep 1
	echo "ensuite :"
	echo ""
	printf "%b\n" "${YELLOW   http://${ip}:4200${NC}\n"
	echo ""
	echo " Ouvrer ce lien dans votre navigateur , il va passer en https , il faut ajouter une execption de sécuriter en cliquant sur avancé "
	echo " Cocher conserver de façon permanante, et vous tomber sur le terminal du pi. fermer la page. "
	echo ""
	echo "touche entrée pour continuer"
	read a
	echo "Ouvrer ce lien dans votre navigateur internet et entrer vos identifiant pour la page admin et régler les derniers paramètres du terrarium"
	echo ""
	printf "%b\n" "${YELLOW   http://${ip}/terraspi/admin/${NC}\n"
	echo ""
	echo ""
	printf "%b\n" "${GREEN}powered${NC}${YELLOW} by ${NC}${LRED}weedmanu${NC}\n"
else
echo "Il faut taper Y ou N!! Pas $ouinon"
fi
exit




