#!/bin/bash

root='/Users/larryhou/Downloads/QQVideo'
find '/Library/Server/Web/Data/Sites/cloud-server.com/电视剧/琅琊榜' -iname '*.txt' | while read clip
do
	episode=${root}/$(echo ${clip} | awk -F'/' '{print $NF}' | sed 's/\.txt$//')
	echo ${clip}
	
	if [ ! -d "${episode}" ]
	then
		mkdir -p ${episode}
	fi

	cat ${clip} | while read mp4
	do
		name=$(echo ${mp4} | awk -F'?' '{print $1}' | awk -F'/' '{print $NF}')
		file="${episode}/${name}"
	
		if [[ ! -f "${file}" ]] || [[ -f "${file}.st" ]]
		then
			url=$(curl -sI ${mp4} | grep 'Location' | awk -F' ' '{print $2}')
			if [ "${url}" = "" ]
			then
				if [ ! "$(curl -sI ${mp4} | grep '^HTTP' | grep '200')" = "" ]
				then
					url=${mp4}
				else
					break
				fi
			fi
			axel -o ${file} ${url} 
		fi
	done
done

