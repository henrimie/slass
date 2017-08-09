#!/bin/bash

for index in $(seq 4); do
        sudo service a3srv${index} restart
	echo -n " #${index}"
	sleep 5s
done
echo $' - DONE\n'

exit 0
