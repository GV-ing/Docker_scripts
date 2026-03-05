#!/bin/bash

if [[ ( $@ == "--help") ||  $@ == "-h" ]]
then 
	echo "Usage: $0 [IMAGE_NAME]"
	#exit 0
else
	if [[ ($# -eq 0 ) ]]
	then 
		echo "Usage: $0 [IMAGE_NAME]"
	else
		SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
		BUILD_CONTEXT="$SCRIPT_DIR/.."
		DOCKERFILE="$SCRIPT_DIR/Dockerfile"
		echo "Building image $1 using Dockerfile $DOCKERFILE and context $BUILD_CONTEXT"
		docker build -t $1 --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) -f "$DOCKERFILE" "$BUILD_CONTEXT"
	fi 
fi 