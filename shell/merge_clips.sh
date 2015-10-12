#!/bin/bash

dir='/Users/larryhou/Downloads/QQVideo/琅琊榜'
find ${dir} -maxdepth 1 -mindepth 1 -type d | while read folder
do
	cd ${folder}
	name=$(echo ${folder} | awk -F'/' '{print $NF}')
	if [[ ! -f "${name}.mp4" ]] || [[ -f "clips.txt" ]]
	then
		find . -iname '*.mp4' | grep '[0-9]\{1,\}\.mp4$' \
			| sort | xargs -I{} echo "file '{}'" > clips.txt
		echo "ffmpeg -f concat -i clips.txt -c copy ${name}.mp4 -y" | xargs -I{} sh -c {}
		rm -f clips.txt
	fi
done