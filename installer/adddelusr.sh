#del users
if [ -d "/home/${usradm}" ]; then
	sudo deluser --remove-home $useradm
fi

if [ -d "/home/${usrlnch}" ]; then
	sudo deluser --remove-home $userlnch
fi
sudo groupdel $grpserver

#mkusers
sudo addgroup $grpserver
sudo adduser $useradm --gecos "" --ingroup $grpserver
sudo usermod -aG sudo $useradm
sudo adduser $userlnch --gecos "" --ingroup $grpserver --disabled-password --shell /bin/false
