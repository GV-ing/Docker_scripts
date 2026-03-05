#!/bin/bash

if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
	echo "Usage: $0 [IMAGE_NAME] [CONTAINER_NAME] [FOLDER_NAME]"
else
	if [[ ($# -eq 0 ) ]]
	then 
		echo "No arguments specified, using wizard mode!"

		echo "Select the docker image ..."
		
		images_nr=$(docker image ls -a | wc -l)
		if [[ $images_nr == 1 ]]
		then
			echo "[ERROR] No docker images available, exiting..."
			exit 0
		fi
	
		i=1
		for c in $(docker image ls -a --format '{{.Repository}}')
		do
			echo $i $c
			i=$(( $i + 1 ))
		done

		read image_index
		i=1
		valid_index=0
		for c in $(docker image ls -a --format '{{.Repository}}')
		do
			if [[ $i -eq $image_index ]]
			then
				img_name=$c
				valid_index=1
			fi
			i=$(( $i + 1 ))
		done
		if [[ $valid_index -eq 0 ]]
		then
			echo "[ERROR] Index not valid, exiting ..."
			exit 0
		fi

		echo "You selected the docker image:" $img_name

		echo "Enter the container name ... [IMG_NAME_cont]"
		read container_name
		if [[ ($container_name == "") ]]
		then
			cont_name=$img_name"_cont"
		else
			cont_name=$container_name
		fi
		echo "The container name is:" $cont_name

		echo "Enter the folder name ... [~/IMG_NAME_fold]"
		read folder_name
		if [[ ($folder_name == "") ]]
		then
			fold_name=${img_name}_fold
		else
			fold_name=$folder_name
		fi
		echo "The folder name is:" $fold_name

	else
		img_name=$1
		cont_name=$2
		fold_name=$3
	fi 	

	HOST_FOLD=/home/$USER/$fold_name
	if [ ! -d "$HOST_FOLD" ] 
	then
		echo "[WARNING] devel folder doesn't exists, creating a new one: $HOST_FOLD"
		mkdir -p "$HOST_FOLD"
	fi

	# If the host folder is empty, avoid mounting it over the image's prebuilt workspace
	MOUNT_WS=1
	if [ -z "$(ls -A "$HOST_FOLD")" ]; then
		# folder is empty
		MOUNT_WS=0
		echo "[INFO] Host folder $HOST_FOLD is empty — skipping mount to avoid overwriting image workspace"
	fi

	xhost +local:root
	if [ $MOUNT_WS -eq 1 ]; then
		docker run --privileged --rm -it --name=$cont_name --net=host --env="DISPLAY=$DISPLAY" \
			--workdir "/root/ros2_ws" \
			--volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
			--volume="$HOST_FOLD:/root/ros2_ws/src:rw" \
			$img_name
	else
		docker run --privileged --rm -it --name=$cont_name --net=host --env="DISPLAY=$DISPLAY" \
			--workdir "/root/ros2_ws" \
			--volume="/tmp/.X11-unix:/tmp/.X11-unix:ro" \
			$img_name
	fi
	xhost -local:root
fi