# duplex output to log
exec &> >(tee ${a3instdir}/scripts/logs/a3update.log)

echo "
In case the download of the game or a mod fails with a timeout, just start runupdate.sh again and again.
This is a known bug of steamcmd in when a download takes long (esp. large mods).

You will now need a steam-user with A3 and the mods subscribed.

Please enter the username of the Steam-User used for the A3-Update:"
read user
echo "Please enter the Steam-Password for $user:"
read -s pw

echo -n "  ... halt servers
"
# halt server(s)
for index in $(seq 4); do
  sudo service a3srv${index} stop
	echo -n " #${index}"
	sleep 2s
done
echo $' - DONE\n'

# (re)build steam script file
# -game
echo "@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir ${a3instdir}/a3master
app_update 233780 validate
quit" > ${a3instdir}/scripts/a3gameupdate.steam

# -mods
echo "@ShutdownOnFailedCommand 1
@NoPromptForPassword 1" > ${a3instdir}/scripts/a3modupdate.steam

while read line; do
        appid=$(echo $line | awk '{ printf "%s", $2 }')
        if [ "${appid}" != "local" ]; then
                echo "workshop_download_item 107410 "${appid}" validate" >> ${a3instdir}/scripts/a3modupdate.steam
        fi
done < ${a3instdir}/scripts/modlist.inp

echo "quit"  >> ${a3instdir}/scripts/a3modupdate.steam

echo -n "
Updating Arma 3...
"
# update game
${steamdir}/steamcmd.sh +login $user $pw +runscript ${a3instdir}/scripts/a3gameupdate.steam
rm -f ${a3instdir}/scripts/a3gameupdate.steam

echo -n "
Updating mods...
"
# update workshop mods
${steamdir}/steamcmd.sh +login $user $pw +runscript ${a3instdir}/scripts/a3modupdate.steam
rm -f ${a3instdir}/scripts/a3modupdate.steam

# (re)make symlinks to the mods
find ${a3instdir}/a3master/_mods/ -maxdepth 1 -type l -delete
while read line; do
  appid=$(echo $line | awk '{ printf "%s", $2 }')
	appname=$(echo $line | awk '{ printf "%s", $1 }')
  if [ "${appid}" != "local" ]; then
		echo "  ... make symlink for app ${appid} to ${appname}"
    ln -s ${steamdir}/steamapps/workshop/content/107410/${appid} ${a3instdir}/a3master/_mods/@${appname}
  fi
done < ${a3instdir}/scripts/modlist.inp

if [[ $antistasi_download_url ]] then
  echo -n "
Downloading and installing Antistasi mission...
"
  # download and install Antistasi mission
  cd $a3instdir
  sudo -u $useradm wget -nv $antistasi_download_url
  antistasirar=${antistasi_download_url##*/}
  sudo -u $useradm unrar x $antistasirar
  antistasimission=${antistasirar%.rar}.pbo
  sudo -u $useradm mv -f ${a3instdir}/${antistasimission} ${a3instdir}/a3master/mpmissions/
  sudo -u $useradm chmod 755 ${a3instdir}/a3master/mpmissions/${antistasimission}
  sudo -u $useradm rm -f ${a3instdir}/${antistasirar}
fi

# reset the file rights in a3master
echo -n "... reseting the file rights in a3master"
find -L $a3instdir/a3master -type d -exec chmod 775 {} \;
find -L $a3instdir/a3master -type f -exec chmod 664 {} \;
chmod 774 $a3instdir/a3master/arma3server
find $a3instdir/a3master -iname '*.so' -exec chmod 775 {} \;
echo $' - DONE\n'

# make all mods lowercase
echo -n "... renaming mods to lowercase"
find -L ${a3instdir}/a3master/_mods/ -depth -execdir rename -f 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
echo $' - DONE\n'

echo -n "
Updating the instances...
"
# update the instances
for index in $(seq 4); do
  if [ -d "${a3instdir}/a3srv${index}" ]; then
    rm -rf $a3instdir/a3srv${index}
  fi
  mkdir $a3instdir/a3srv${index} --mode=775
  ln -s ${a3instdir}/a3master/* $a3instdir/a3srv${index}/
	rm -f $a3instdir/a3srv${index}/keys
	mkdir $a3instdir/a3srv${index}/keys --mode=775
done

echo -n "... starting the server and headless clients"
# bring server(s) back up
for index in $(seq 4); do
        sudo service a3srv${index} start
	echo -n " #${index}"
	sleep 3s
done
echo $' - DONE\n'
