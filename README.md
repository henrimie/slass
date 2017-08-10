<p align="center">
    <strong>Arma3 Co-operative Server Installer and Manager</br>
    <sup>short: acsiam</br>
	  Tested on Ubuntu 16.04 (Xenial)</br>
    </br>
    Based on seelenlos's <a target="_blank" href="https://github.com/joka-de/slass">Arma 3 server script</a>
    </strong></sup></p>

<p align="center">License: GNU GPLv3</p>

<p align="center"><a target="_blank" href="https://github.com/henrimie/acsiam/releases/">Download latest version.</a></p>

## General
This script will greatly ease the installation and management of an <a target="_blank" href="http://www.a3antistasi.com/mod">Arma3 Antistasi</a> server including required mods from the Steam workshop.</br></br>This is not a one-click-get-a-server script. Its usage is simple, but do yourself a favor and read this manual BEFORE you begin. Really. Basic knowledge of the linux command line usage is assumed.

## What it does
The acsiam Arma 3 Antistasi Server Script
- installs one arma3 server instance and three <a target="_blank" href="https://community.bistudio.com/wiki/Arma_3_Headless_Client">arma3 headless client</a> instances on Linux
- saves precious storage by using symlinks (about the space for one installation is needed)
- implements the instances as services in the OS
- restarts the servers if they crash
- provides diagnostic commands on the running servers
- installs Arma3 mods from the workshop
- provides a central config file where you can specify an mod set
- differentiates between mod, servermod, and clientmod
- manages the *.bikey files in dependency of the loaded mods
- reconfigures the servers upon each restart according to the config files
- can be used to update Arma3 and the mods by a single command
- provides a simple way to have an almighty admin and a maintance user, who can update/install mods, and add missions, but not fumble around in the important scripts

## How it works

**Basic Structure**
The script will generate a master installation (a3master), that will never be started. Using symlinks, it will build one server instance and three headless client instances out of this master installation. The instances are later run as a system service (SysVInit). The whole set of server files, including the mission repository (mpmissions folder) and *.Arma3Profile is being shared among the instances, but the instances use individual config files. A script will manage the mods and their keys to load.</br>

All instances will share</br>

- the Arma3-files and mod files (update all instances at once)
- the *.Arma3Profile
- basic config settings
- a common logfile folder

**What happens on installation**
You begin by putting the script folder **installer** into an arbitrary folder on your system (ie. /srv/arma3). Upon start, the script will then establish an Arma3 installation inside that arbitrary folder. Depending on you installation path, it will build individual config and script files for your server, headless clients, install steamcmd, set the required file ownerships and rights, and install the servers as a system service. The installation finishes with an update of Arma3 and the mods. Lastly the installation donwloads a copy of Antistasi and copies it over to the mission repository.
Refer to the file **doc/folder_struc.png** for a general overview where to find the files and what they do (original <a target="_blank" href="https://github.com/joka-de/slass">slaas</a> folder structure, doesn't have acsiam modifications).

**What happens on update**
File ownership in a3master will be reset to avoid issues from remote upload of mission files etc. The server and headless client instances are then stopped, and an update (or install, if not already there) of Arma3 and the mods is performed. After the update, the file rights in a3master are reset, all mods are renamed to lower case (avoids issues with crashing mods on linux) and the folders of the instances are cleared and rebuild. Finally, the sever and headless clients are booted back up.

**What happens on start/restart**
On start, all config files are newly read in to consider possible config edits. The config file **modlist.inp** defines the mods to load, pre-configured by the installer for Antistasi experience (you can choose the basic set with realism enhancements etc. or the extended set with addittional audio and visual mods supported by Antistasi, more at Appendix IV. at the bottom of the readme). Depending on that config the startup options are build. Then the script will generate the config file for the respective instance, and copy the individually needed set of **.bikey - files** into its **keys** folder. Logfiles older than {deldays} **(servervars.cfg)** will be deleted, a new logfile will be written. Afterwards, the instance will boot, being monitored by a watchdog process. The watchdog reboots the server if it crashes. The watchdog is also active if the server stopped externally, i.e. you can issue the #shutdown command ingame to read an updated server config.

## Installation

**1. Prerequisites**
- ensure you have the root password for your machine at hand
- create an arbitrary folder for the servers, we suggest **/srv/arma3/**
- copy the script folder "installer" in that folder, e.g. **/srv/arma3/installer**
- open the file **install.cfg** inside the folder "installer", change the user informations therein to your wishes. The users can be created by the script, or manually before you start the installation; refer to the commands in **./installer/adddelusr.sh** on how to do so. They will have the following functions</br>
-- **useradm** - Is owner of the files in the server folder, can add/delete/modify files and manage servers. You can use your normal user account with sudo privileges for this. Make sure he is in **grpserver** (see below).</br>
-- **userlnch** - Is the owner of the server process once fired up. For security reasons, he should not be able to get a shell nor become root.
</br></br>*Use strong Passwords for both users anyway, never hand them out! A server with web access is not a toy!*</br></br>
-- **grpserver** - a user group in which both preceding noted users must be, preferably as initial-group. Add additional users to that group, to allow them to make basic maintenance of the gameserver (update, mod/mission install, restart, cfg changes)</br>
-- **a3srvpass** - Password (if desired, can be left empty) for joining your to be created Arma 3 Antistasi server
-- **antistasi_download_url** - URL to be used for Antistasi download. Check latest from <a target="_blank" href="http://www.a3antistasi.com/mod">http://www.a3antistasi.com/mod</a></br>
ie. for non-beta Antistasi Altis:</br> https://s3.amazonaws.com/files.enjin.com/1218665/Antistasi%20Game%20Files/ALTIS/public_versions/Antistasi.Altis.rar
- prepare the server config files in **./installer/rsc**</br>
**a3common.cfg** - master config file containing settings common for all server instances.</br>
**basic.cfg** - loaded as -cfg file by the server process</br>
**servervars.cfg** - config file setting additional options for the server executable, normally you don't need to edit this</br>
- determine the mods to install (not necessary by default for Antistasi Server), to do so edit **./installer/rsc/modlist.inp** or **./installer/rsc/modlistextd.inp** depending on if you're going to use the basic or extended modset as the template. The files have seven columns:</br>
	I. shortname of the mod</br>
	II. steam-app-id of the mod; if the mod is not in the workshop, insert the word **local**</br>
 	III. mod type; use</br>
		**mod** if the mod is to be loaded by server and client (key and mod is loaded), e.g. ACE</br>
		**cmod** if the mod is only to be loaded client side (only mod is loaded), e.g. JSRS</br>
		**smod** if the mod is only to be loaded by the server (only key is loaded), e.g. ace_server</br>
	IV. to VII. contains a binary key 0/1 selecting if the mod is to be loaded on server or headless client #1(a3server)/#2(hc1)/#3(hc2)/#4(hc3)</br>
**prepserv.sh** - defines the server name, among other stuff. Edit the entry **hostname_base="Generic Arma3"** and the entry **" hostname id1=' Antistasi Altis' to your wishes. The final server name will be composed as</br>
**Hostname_base+hostname_id1**, e.g. **"Generic Arma3 Antistasi Altis"**</br>Don't edit more of the file or you will break it...
**profile.Arma3Profile** - the Arma3Profile of the Server, set difficulty there</br>
- Make sure that you have the steam login of a user with arma3 purchased and the mods being stated in "modlist.inp" subscribed at hand.

**3. Start Installation**
- ensure the file **./installer/a3install.sh** is executable for your current user (chown , chmod 744)
- run **sudo ./installer/a3install.sh** , confirm continuation request
- decide, if you want the users to be created, see above
- the script may ask you to install some packages named like libc6.., those are needed by steamcmd
- consider saving or immediately applying the commands printed on the prompt (ln) in another console; refer to the *Usage-Update* section below
- confirm the begin of the download, or choose to download later by issuing the update script (see below).
- The login into steam may fail on the first try, because you are probably logging in from a machine unknown to steam. In this case the script will freeze at the line "Verifiying Login-Data...". Abort the script by pressing **Ctrl-C** in that case. Then start **/srv/arma3/steamcmd/steamcmd.sh** and enter the guard code received per mail. Refer to the steamcmd manual on HowTo, or see below. Afterwards restart the update process by issuing **sudo /srv/arma3/scripts/runupdate.sh**. **runupdate.sh** from now on will always be the file to start in order to **update arma3 or install a mod**.
- If you use **two-factor authentication** the install/update script will pause at **login USERNAME ----**, this is when you should input your **two-factor token** and press **enter**. It will pause for the **two-factor token** once for Arma3 and once for mods.
- when you see **app_update 233780 validate** arma3 is being downloaded, be patient
- note the output on screen. If the installation of mods **...workshop_download_item ...** fails with timeout, abort the update process with **Ctrl-C**. This will happen if you download a large mod for the first time and the download takes long. The download attempts are cumulative, so each time you run the update, you make progress. For RHS for instance I needed to run the script 5 times. The issue is a bug in steamcmd.

**4. Done**</br>
Enjoy Arma3 Antistasi! You may delete the **installer** folder now.

## Usage
**1. Manage Servers**</br>
The servers are implemented into your system as system services. You **manage** them by issuing the command</br>
**sudo service a3srvX OPTION**</br>
Replace X with the number of the server and OPTION with</br>
**start** - you guess it</br>
**stop** - ahem...well</br>
**restart** - Does a restart. If you have many big mods loaded, this command may fail because the server takes to long to stop. Just issue **stop** and after a short wait **start** again.</br>
**status** - prints the service status</br>
**log** - prints the serverlog onto the prompt in realtime as it is written, abort with Ctrl-C</br></br>
**Update** the servers and mods by running **sudo /srv/arma3/scripts/runupdate.sh**. The script will then download/update A3 and the workshop-mods registered in **modlist.inp**.</br>
You will also need to execute the command</br>
*ln -s /home/{useradmin}/Steam /home/{userupdate}/Steam*</br>
for each user you want to enable to run the update script. Run the command as the user {userupdate}. Replace {useradmin} and {userupdate} with the respective user names. The command will create a symlink of the Steam cache folder into the home directory of {userupdate}. This forces steam to use only one repository of cache files for all users, preventing several issues.

**2. Install mods**</br>
For **workshop** mods: Ensure you have the mod subscribed for the user you wish to use for the update. Write an entry for the mod to install into modlist.inp as described in the installation section. Run an update.</br></br>
For **non-workshop** (i.e. local) mods: Put the mod into **/srv/arma3/a3master/_mods/** and copy the **.bikey** file (if one is needed) in a respective folder **./_mods/@modname/keys**. Set the file owner and permissions like the other mods have it. You may alternatively run an update to let the script set the permissions. Write an entry for the mod to install into **modlist.inp** as described in the installation section. Reboot the a3srv1 to load the mod. </br></br>
In both cases, ensure the **.bikey** file (if one is needed) is in a folder **{a3instdir}/a3master/_mods/@modname/keys**, if you observe problems loading the mod. Otherwise the script won't find it.

**3. Edit server configs**</br>
Thats simple: Edit what you need to, and restart the a3server.

## Appendix
**I. Enter Steam Guard code**
- run **{a3instdir}/steamcmd/steamcmd.sh**; make sure you run this command as {useradmin} or a {userupdate} for whom the *ln* command has already been applied
- input **login USERNAME**
- input the **guard code**
- input **exit**

**II. Updating or changing the Antistasi mission file**
- run **sudo {a3instdir}/arma3/scripts/runupdate.sh {antistasi_download_url}**</br>
obviously replacing {antistasi_download_url} with your desired Antistasi mission .rar url.
- if **mission filename** changed remember to change **{a3instdir}/a3master/cfg/a3indi1.cfg**</br>
and update template to:</br></br>
class mission1</br>
                {</br>
                template = {antistasi_mission_file_without_.pbo_ending};</br>
                };

**III. Changing Arma 3 server password for joining**
- Edit both</br>
-- **{a3instdir}/a3master/cfg/a3common.cfg**</br>
    password = "empty or desired password";</br></br>
-- **{a3instdir}/scripts/service/servervars.cfg**</br>
    a3srvpass=empty or desired password

**IV. Modlists**
- **No mods / vanilla**</br>
Self explanatory.</br></br>
- **Basic modlist:**</br>
<sup>(<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=1106546686">Basic Mod collection for easy subscription.</a>)</sup></br></br>
<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=450814997">CBA_A3</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=843425103">RHSAFRF</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=843577117">RHSUSAF</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=843593391">RHSGREF</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=843632231">RHSSAF</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=463939057">ACE</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=773131200">ACE Compat - RHSAFRF</a>,</br>
<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=773125288">ACE Compat - RHSUSAF</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=884966711">ACE Compat - RHSGREF</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=437407341">XLA_FixedArsenal</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=333310405">Enhanced Movement</a></br></br>
- **Extended modlist (added to basic modlist):**</br>
<sup>(<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=1106548354">Extended Mod collection for easy subscription.</a>)</sup></br></br>
<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=814650855">Dusty's RHS</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=804952618">Retexture Project</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=861133494">JSRS SOUNDMOD</a>,</br>
<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=863393819">JSRS - Additional Weap Sounds</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=870212593">JSRS - RHS - Vehicles Sound Patch</a>,</br>
<a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=872471132">JSRS - RHS - Weapons Sound Patch</a>, <a target="_blank" href="https://steamcommunity.com/sharedfiles/filedetails/?id=767380317">Blastcore</a>
