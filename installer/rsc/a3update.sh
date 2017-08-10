antistasi_download_url=$1
execdownload="y"

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

# halt server(s)
echo -n "
... halt servers
"
for index in $(seq 4); do
  sudo service a3srv${index} stop
  echo -n " #${index}"
  sleep 2s
done
echo $' - DONE\n'

# build steam script file - game
tmpfile=$(mktemp)
echo "@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir ${a3instdir}/a3master
login $user $pw" >> $tmpfile
if [ "${execdownload}" == "y" ]; then
	echo "app_update 233780 validate" >> $tmpfile
fi
echo "quit" >> $tmpfile

# update game
echo -n "
Updating Arma 3...
"
${steamdir}/steamcmd.sh +runscript $tmpfile | sed -u "s/${pw}/----\n\nEnter two-factor code if used:/g" &
steampid=$!
wait $steampid
rm $tmpfile

# request update halt
goon="n"
while [ "$goon" != "y" ]; do
echo -n "
If you want to manually expand the server with non-workshop mods, missions, etc. now would be the time to do so
in antoher console. Remember to set the appropiate owner and group for the content.
Type y if you are done and want to go on with the update.

Go on? (y) "
read goon
done

# build steam script file - mods
tmpfile=$(mktemp)
echo "@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
DepotDownloadProgressTimeout 600
force_install_dir ${a3instdir}
login $user $pw" >> $tmpfile

while read line; do
  appid=$(echo $line | awk '{ printf "%s", $2 }')
  if [ "${execdownload}" == "y" ] && [ "${appid}" != "local" ]; then
    echo "workshop_download_item 107410 "${appid}" validate" >> $tmpfile
	fi
done < ${a3instdir}/scripts/modlist.inp

echo "quit"  >> $tmpfile

# update workshop mods
echo -n "
Updating mods...
"
${steamdir}/steamcmd.sh +runscript $tmpfile | sed -u "s/${pw}/----\n\nEnter two-factor code if used:/g" &
steampid=$!
wait $steampid
rm $tmpfile

# (re)make symlinks to the mods
echo -n "
(re)making symlinks to mods...
"
find ${a3instdir}/a3master/_mods/ -maxdepth 1 -type l -delete
while read line; do
  appid=$(echo $line | awk '{ printf "%s", $2 }')
	appname=$(echo $line | awk '{ printf "%s", $1 }')
  if [ "${appid}" != "local" ]; then
		echo "  ... make symlink for app ${appid} to ${appname}"
    ln -s ${a3instdir}/steamapps/workshop/content/107410/${appid} ${a3instdir}/a3master/_mods/@${appname}
  fi
done < ${a3instdir}/scripts/modlist.inp

# get rhs incl. keys - obsolete, may be used as template
#wget -m -nv -nH --cut-dirs=2 --retry-connrefused --timeout=30 -P ${a3instdir}/a3master/_mods/@rhsafrf ftp://ftp.rhsmods.org/beta/rhsafrf/
#wget -m -nv -nH --cut-dirs=2 --retry-connrefused --timeout=30 -P ${a3instdir}/a3master/_mods/@rhsafrf/keys/ ftp://ftp.rhsmods.org/beta/keys/rhsafrf.0.4.1.1.bikey
#wget -m -nv -nH --cut-dirs=2 --retry-connrefused --timeout=30 -P ${a3instdir}/a3master/_mods/@rhsusaf ftp://ftp.rhsmods.org/beta/rhsusaf/
#wget -m -nv -nH --cut-dirs=2 --retry-connrefused --timeout=30 -P ${a3instdir}/a3master/_mods/@rhsusaf/keys/ ftp://ftp.rhsmods.org/beta/keys/rhsusaf.0.4.1.1.bikey
#wget -m -nv -nH --cut-dirs=2 --retry-connrefused --timeout=30 -P ${a3instdir}/a3master/_mods/@rhsgref ftp://ftp.rhsmods.org/beta/rhsgref/
#wget -m -nv -nH --cut-dirs=2 --retry-connrefused --timeout=30 -P ${a3instdir}/a3master/_mods/@rhsgref/keys/ ftp://ftp.rhsmods.org/beta/keys/rhsgref.0.4.1.1.bikey

# download and install/update/change Antistasi mission
if [[ $antistasi_download_url ]]; then
  echo -n "
Updating/changing Antistasi mission...
"
  antistasirar=${antistasi_download_url##*/}
  antistasimission=${antistasirar%.rar}.pbo
  cd $a3instdir
  echo -n "
... downloading $antistasirar

"
  sudo -u $useradm wget -nv $antistasi_download_url
  sudo -u $useradm unrar x $antistasirar
  echo -n "
Moving ${antistasimission} to ${a3instdir}/a3master/mpmissions/ ...

"
  sudo -u $useradm mv -f ${a3instdir}/${antistasimission} ${a3instdir}/a3master/mpmissions/
  sudo -u $useradm chmod 755 ${a3instdir}/a3master/mpmissions/${antistasimission}
  echo -n "
Removing ${antistasirar}...
  "
  sudo rm -f ${a3instdir}/${antistasirar}

  echo -n "
Antistasi mission downloaded and copied to: ${a3instdir}/a3master/mpmissions/${antistasimission}
if mission filename changed remember to change ${a3instdir}/a3master/cfg/a3indi1.cfg
and update template to:

class mission1
                {
                template = ${antistasirar%.rar};
                };

"
  sleep 10s
fi

# reset the file permissions in a3master
echo -n "
...reseting the file permissions in a3master"
find -L $a3instdir/a3master -type d -exec chmod 775 {} \;
find -L $a3instdir/a3master -type f -exec chmod 664 {} \;
chmod 774 $a3instdir/a3master/arma3server
find $a3instdir/a3master -iname '*.so' -exec chmod 775 {} \;
echo $' - DONE\n'

# make all mods lowercase
echo -n "
... renaming mods to lowercase"
find -L ${a3instdir}/a3master/_mods/ -depth -execdir rename -f 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
echo $' - DONE\n'

# install/update @aceserver mod if @ace found
if [ -d "${a3instdir}/a3master/_mods/@ace"]; then
  echo -n "
Updating @aceserver mod...
"
  if [ -d "${a3instdir}/a3master/_mods/@aceserver" ]; then
    sudo rm -rf ${a3instdir}/a3master/_mods/@aceserver
  fi
  sudo -u $useradm mkdir ${a3instdir}/a3master/_mods/@aceserver --mode=775
  sudo -u $useradm mkdir ${a3instdir}/a3master/_mods/@aceserver/addons --mode=775
  sudo -u $useradm ln -s ${a3instdir}/a3master/_mods/@ace/optionals/ace_server.pbo ${a3instdir}/a3master/_mods/@aceserver/addons/

# install/update Antistasi Companion Mod (@dgc_fiaveh)
echo -n "
Install/update Antistasi Companion Mod (@dgc_fiaveh)?
( http://www.a3antistasi.com/mod at Antistasi Altis - Extras )
Leave empty if not wanted.

Enter dgc_fiaveh download url: "
read dgc_fiaveh_url

if [ "$dgc_fiaveh_url" != "" ]; then
  dgcrar=${$dgc_fiaveh_url##*/}
  cd $a3instdir
  echo -n "

... downloading $dgcrar
"
  sudo -u $useradm wget -nv $dgc_fiaveh_url
  sudo -u $useradm unrar x $dgcrar
  echo -n "
Moving @dgc_fiaveh to ${a3instdir}/a3master/_mods/ ...
"
  if [ -d "${a3instdir}/a3master/_mods/@dgc_fiaveh" ]; then
    sudo rm -rf ${a3instdir}/a3master/_mods/@dgc_fiaveh
  else
    sudo -u $useradm bash -c "echo \"dgc_fiaveh      local           smod    1 0 0 0\" >> ${a3instdir}/scripts/modlist.inp"
  fi
  sudo -u $useradm mv ${a3instdir}/@dgc_fiaveh ${a3instdir}/a3master/_mods/
  sudo -u $useradm chmod -R 755 ${a3instdir}/a3master/_mods/@dgc_fiaveh
  echo -n "
Removing $dgcrar..."
  sudo rm -f ${a3instdir}/${dgcrar}
fi

# (re)create the folders of the instances
echo -n "
(re)creating the folders of the instances...
"
for index in $(seq 4); do
  if [ -d "${a3instdir}/a3srv${index}" ]; then
    rm -rf $a3instdir/a3srv${index}
  fi
  mkdir $a3instdir/a3srv${index} --mode=775
  ln -s ${a3instdir}/a3master/* $a3instdir/a3srv${index}/
	rm -f $a3instdir/a3srv${index}/keys
	mkdir $a3instdir/a3srv${index}/keys --mode=775
done

echo -n "
... starting the server and headless clients
"
# bring server(s) back up
for index in $(seq 4); do
        sudo service a3srv${index} start
	echo -n " #${index}"
	sleep 3s
done

echo $' - DONE\n'
