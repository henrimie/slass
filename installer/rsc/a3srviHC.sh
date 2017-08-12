# read server settings
. ${basepath}/scripts/service/servervars.cfg

# set path variables
arma_dir=${basepath}/a3srv${serverid}
echo "Working on armadir: $arma_dir"
name=a3srv${serverid}
port=2302
cfg_dir=${arma_dir}/cfg
config=${cfg_dir}/${name}.cfg
cfg=${cfg_dir}/basic.cfg
log_dir=${arma_dir}/log
pidfile=${arma_dir}/${name}.pid
runfile=${arma_dir}/${name}.run
logfile=${log_dir}/${name}_$(date +%Y-%m-%d_%H:%M:%S).log
server=${arma_dir}/arma3server

hcprofile=${profile}hc${serverid}

#=======================================================================
ulimit -c 1000000
#
case "$1" in
#
#
start)
# check if there is a server running or not
ps ax | grep ${server} | grep ${port} > /dev/null

if [ $? -eq 0 ]; then

echo "\033[31mthere is a headless client already running (${name})\033[0m"
echo "\033[31mit can happen, when you started a server and stopped it to fast!\033[0m"
echo "\033[31mjust stop the server again and it should be good to start!\033[0m"
echo $output | ps ax | grep ${server} | grep ${port}

else

echo "starting a3 headless client ${name} \033[35m${server}\033[0m..."

# file to mark we want server running...
echo "go" >${runfile}

#prepare server env (keys, modlist, hostname)
. ${basepath}/scripts/service/prepserv.sh

# launch the background watchdog process to run the server
nohup </dev/null >/dev/null $0 watchdog &
echo ""
fi
;;
#
stop)
echo "stopping a3 headless client if there is one ${name} (\033[35m${server}\033[0m)..."
if [ -f ${runfile} ]; then
# ask watcher process to exit by deleting its runfile...
rm -f ${runfile}
else
echo "\033[31mthere is no runfile (${runfile}), headless client shouldn't be up, will shut it down if it is up!\033[0m"
fi
# and terminate arma 3 server process
if [ -f ${pidfile} ]; then
echo "sending sigterm to process $(cat ${pidfile})..."
kill $(cat ${pidfile})
if [ $?==0 ]; then
rm -f ${pidfile}
fi
fi
;;
#
status)
if [ -f ${runfile} ]; then
echo "\033[32mrunfile exist, headless client should be up or is starting...\033[0m"
echo "\033[35mif the headless client is \033[31mnot done\033[35m with its start, you will \033[31mnot get\033[35m a pid file info in the next rows.\033[0m"
echo "\033[35mif the headless client is \033[32mdone\033[35m with its start, you will \033[32mget\033[35m a pid file and process info in the next rows.\033[0m"
else
echo "\033[31mrunfile doesn't exist, headless client should be down or is going down...\033[0m"
fi
if [ -f ${pidfile} ]; then
pid=$(< ${pidfile})
echo "\033[32mpid file exists (pid=\033[35m${pid}\033[0m)..."
if [ -f /proc/${pid}/cmdline ]; then
echo "\033[32mheadless client process seems to be running...\033[0m"
#echo $output |
ps ax | grep ${server}
fi
fi
;;
#
restart)
$0 stop
sleep 15s
$0 start
;;
#
watchdog)
# delete old logs when older then ${deldays} days
echo >>${logfile} "watchdog ($$): [$(date)] deleting all logfiles in ${log_dir} when older then ${deldays} days."
find -L ${log_dir} -iname "*.log" -mtime +${deldays} -delete
#
# this is a background watchdog process. do not start directly
while [ -f ${runfile} ]; do
# launch the server...
cd ${arma_dir}
echo >>${logfile} "watchdog ($$): [$(date)] starting headless client ${name} (\033[35m${server}\033[0m)..."
#
sudo -u ${username} ${server} >>${logfile} 2>&1 -client -connect=127.0.0.1 -password=${a3srvpass} -port=${port} -profiles=${hcprofile} -mod=${mods} &
pid=$!
echo $pid > $pidfile
chmod 664 $logfile
chown ${useradm}:${profile} $logfile
wait $pid
#
if [ -f ${runfile} ]; then
echo >>${logfile} "watchdog ($$): [$(date)] headless client ${name} died, waiting to restart..."
sleep 5s
else
echo >>${logfile} "watchdog ($$): [$(date)] headless client ${name} shutdown intentional, watchdog terminating"
fi
done
;;

log)
# you can see the logfile in realtime, no more need for screen or something else
clear
echo "printing headless client log of ${name}"
echo "- to stop, press ctrl+c -"
echo "========================================"
#sleep 1
tail -fn5 ${log_dir}/$(ls -t ${log_dir} | grep ${name} | head -1)
;;
#
#
*)
echo "$0 (start|stop|restart|status|log)"
exit 1
;;

esac
