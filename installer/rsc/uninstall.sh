. ${basepath}/scripts/service/servervars.cfg

echo -n "This script will remove acsiam Arma 3 Antistasi server and headless
clients completely. It will remove associated users created at installation,
remove system services and init-files, empty the Server installation folder
removing and deleting steamcmd, userconfigs, downloaded mods, local mods.

Are you sure you want to continue? (y/n) "
read goinst
if [ $goinst != "y" ]; then
	exit 0
fi

echo -n "




----------------------------------------------
!!!PLEASE MAKE SURE TO TAKE ANY NEEDED BACKUPS!!!

The whole ${basepath} folder will be emptied!

${usradm} and ${username} homefolders will be deleted!

${profile}.Arma3Profile and ${profile}.vars.Arma3Profile (.vars. contains
the Antistasi persistent save for your server!!) will be deleted in
/home/${username}/.local/share/Arma 3 - Other Profiles/${profile}/

!!!PLEASE MAKE SURE TO TAKE ANY NEEDED BACKUPS!!!
----------------------------------------------


Are you still sure you want to continue? (y/n) "
read goinstint
if [ $goinstint != "y" ]; then
	exit 0
fi

# halt server(s)
echo -n "
... halting servers (if any) and removing init-scripts & system services"
for index in $(seq 4); do
  echo "

-- #${index}
"
  sudo /etc/init.d/a3srv${index} stop
  sleep 5s
  sudo update-rc.d a3srv${index} remove
	sudo rm -v /etc/init.d/a3srv${index}
done
echo $' - DONE\n'

# del users
echo "

... deleting users, home folders and group
"
if [ -d "/home/${usradm}" ]; then
	sudo deluser --remove-home $useradm
fi

if [ -d "/home/${username}" ]; then
	sudo deluser --remove-home $username
fi
sudo groupdel $profile

# empty server installation folder
echo "

... emptying server installation folder
"
sudo rm -rfv ${basepath}/*

echo "


 - ALL DONE
"

exit 0
