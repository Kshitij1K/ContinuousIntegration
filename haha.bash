#!/bin/bash

# test "" = "$(grep '^haha: ' "list.txt" |
# 	 sort | uniq -c | sed -e '/^[ 	]*1[ 	]/d')" || {
# 	echo >&2 Duplicate Signed-off-by lines.
# 	exit 1
# }

DOCKERREPO=

MYVAR=$(grep -oE '\bv([1-9][0-9]*|0)\.([1-9][0-9]*|0)\.([1-9][0-9]*|0)\b' list.txt |
        sed 's/v//')

if [ "$MYVAR" = "" ] ; then
    echo "A valid version number was not found in the commit message. Aborting."
    echo "Version number should be written in the following example format: 'v123.123.123'."
    echo "Please run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
    exit 1
else
    echo "Checking whether version $MYVAR already exists on server."
    
    JQCHECK=$(dpkg -l | grep ' jq ')
    
    if [ "${JQCHECK:-0}" == 0 ] ; then
        echo "The library jq is needed for parsing the JSON text returned by querying Docker Hub for the list of tags, and it isn't installed. Installing."
    
        if sudo apt-get update > /dev/null && sudo apt-get install --yes jq > /dev/null ; then
            echo "The library jq has been successfully installed."
        else
            echo "The jq library failed to install. Please try installing it manually with 'apt install jq' and then try again."
            echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
            exit 2
        fi
    fi
    
    TAGCHECK=$(curl 'https://registry.hub.docker.com/v2/repositories/kshitijkabeer/continuous-integration-ros-ws/tags/' | jq '."results"[]["name"]' | grep "$MYVAR" | sed 's/"//g')
    
    if [ "${TAGCHECK:-0}" != 0 ] ; then
        echo "The tag $MYVAR already exists on server. Please give a different name and try again."
        echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
        echo $TAGCHECK
        exit 3
    else
        echo "Version name is unique. Checking whether image already exists locally on computer."
        LOCALCHECK=$(sudo docker images | grep "$TAGCHECK")
        
        
        if [ $]    
    fi 


fi