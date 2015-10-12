#!/bin/bash

TV_NAME='琅琊榜'
while getopts :t:h OPTION
do
	case ${OPTION} in
		t) TV_NAME=${OPTARG};;
		h) echo "Usage: $(basename $0) -t [TV_NAME] -h [HELP]"
		   exit;;
		:) echo "ERR: -${OPTARG} 缺少参数, 详情参考: $(basename $0) -h" 1>&2
		   exit 1;;
		?) echo "ERR: 输入参数-${OPTARG}不支持, 详情参考: $(basename $0) -h" 1>&2
		   exit 1;;
	esac
done

root='/Users/larryhou/Downloads/QQVideo'
if [ ! -d "${root}/${TV_NAME}" ]
then
	mkdir -pv "${root}/${TV_NAME}"
fi

find "/Library/Server/Web/Data/Sites/cloud-server.com/电视剧/${TV_NAME}" -iname '*.txt' | while read clip
do
	episode="${root}/${TV_NAME}/$(echo ${clip} | awk -F'/' '{print $NF}' | sed 's/\.txt$//')"
	echo ${clip}
	
	if [ ! -d "${episode}" ]
	then
		mkdir -p "${episode}"
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
			axel -o "${file}" ${url} 
		fi
	done
done

