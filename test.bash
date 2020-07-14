#!/bin/bash

DOCKERFILECHECK=$(git diff --cached --name-status | grep 'Dockerfile')

if [ -z "$DOCKERFILECHECK" ] ; then
    echo "Dockerfile isn't being committed, so no need to check the commit message."
    exit 0
fi

DOCKERREPO=$(git branch | grep \* | sed 's/* deploy\///' | sed 's/* test\///')

DEPLOYCHECK=$(git branch | grep \* | sed 's/* deploy\///' | sed 's/'"$DOCKERREPO"'//')
if [ -z "$DEPLOYCHECK" ] ; then
    echo "This is a deployment image"
fi

VERSION=$(grep -oE '\bv([1-9][0-9]*|0)\.([1-9][0-9]*|0)\.([1-9][0-9]*|0)\b' $1 |
        sed 's/v//')

if [ -z "$VERSION" ] ; then
    echo "A valid version number was not found in the commit message. Aborting."
    echo "Version number should be written in the following example format: 'v123.123.123'."
    echo "Please run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
    exit 1
fi

echo "Checking whether version $VERSION already exists on server."

JQCHECK=$(dpkg -l | grep ' jq ')

if [ -z "$JQCHECK" ] ; then
    echo "The library jq is needed for parsing the JSON text returned by querying Docker Hub for the list of tags, and it isn't installed. Installing."

    if sudo apt-get update > /dev/null && sudo apt-get install --yes jq > /dev/null ; then
        echo "The library jq has been successfully installed."
    else
        echo "The jq library failed to install. Please try installing it manually with 'apt install jq' and then try again."
        echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
        exit 2
    fi
fi

echo $DEPLOYCHECK

if [ -z "$DEPLOYCHECK" ] ; then
    TAGS=$(curl 'https://registry.hub.docker.com/v2/repositories/ariitk/deployment/tags/' | jq '."results"[]["name"]' | sed 's/"//g' | sed 's/'"$DOCKERREPO"'-//')
else
    TAGS=$(curl 'https://registry.hub.docker.com/v2/repositories/ariitk/'"$DOCKERREPO"'/tags/' | jq '."results"[]["name"]' | sed 's/"//g')
fi

/usr/bin/python3 .git/hooks/check_version.py $VERSION $TAGS

VERSIONCHECK=$?

if [ $VERSIONCHECK -eq 1 ] ; then
    exit 3
fi

if [ $VERSIONCHECK -eq 2 ] ; then
    read -r -p "Are you sure you want to push this version? [y/N] " response < /dev/tty
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
        echo "Proceeding to build with this version as the tag."
    else
        echo "Aborting. Give another version name, and then try again."
        echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
        exit 3
    fi
fi

echo "Checking whether image is already built or not."

if [ -z "$DEPLOYCHECK" ] ; then
    LOCALCHECK=$(sudo docker images | grep deployment |grep "$DOCKERREPO-$VERSION")
else
    LOCALCHECK=$(sudo docker images | grep "$DOCKERREPO" | grep "$VERSION")
fi 

if [ -n "$LOCALCHECK" ] ; then
    echo "Image already exists on computer."
    read -r -p "Do you want to overwrite it? [y/N] " response < /dev/tty
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] ; then
        if [ -z "$DEPLOYCHECK" ] ; then
            echo "Building image with name ariitk/deployment:$DOCKERREPO-$VERSION"
            if sudo docker build -t ariitk/deployment:$DOCKERREPO-$VERSION . ; then
                echo "The build succeeded."
            else
                echo "The build failed. Please rectify the Dockerfile and try again."
                echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
                exit 4
            fi
        else
            echo "Building image with name ariitk/$DOCKERREPO:$VERSION"
            if sudo docker build -t ariitk/$DOCKERREPO:$VERSION . ; then
                echo "The build succeeded."
            else
                echo "The build failed. Please rectify the Dockerfile and try again."
                echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
                exit 4
            fi
        fi        

    else
        echo "Aborting. Please give a unique name and try again."
        echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
        exit 5
    fi
else
    if [ -z "$DEPLOYCHECK" ] ; then
        echo "Building image with name ariitk/deployment:$DOCKERREPO-$VERSION"
        if sudo docker build -t ariitk/deployment:$DOCKERREPO-$VERSION . ; then
            echo "The build succeeded."
        else
            echo "The build failed. Please rectify the Dockerfile and try again."
            echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
            exit 4
        fi
    else
        echo "Building image with name ariitk/$DOCKERREPO:$VERSION"
        if sudo docker build -t ariitk/$DOCKERREPO:$VERSION . ; then
            echo "The build succeeded."
        else
            echo "The build failed. Please rectify the Dockerfile and try again."
            echo "Or, run git commit with the '--no-verify' option to skip checking and building the Dockerfile, and pushing the image to DockerHub (Not recommended)"
            exit 4
        fi
    fi
fi


echo "Pushing the image(s) to Dockerhub. Please enter your credentials if required."

if [ -z "$DEPLOYCHECK" ] ; then
    if sudo docker login && sudo docker push ariitk/deployment:$DOCKERREPO-$VERSION ; then
        echo "Push succeeded."
    else 
        echo "Push to Dockerhub failed. Maybe check your internet connection/enter correct credentials"
        exit 5
    fi

    if [ $VERSIONCHECK -eq 0 ] ; then
        echo "Since this is the latest version, also building and pushing image with name ariitk/deployment:$DOCKERREPO-latest"
        sudo docker build -t ariitk/deployment:$DOCKERREPO-latest .
        if sudo docker login && sudo docker push ariitk/deployment:$DOCKERREPO-latest ; then
            echo "Push succeeded."
        else 
            echo "Push to Dockerhub failed. Maybe check your internet connection/enter correct credentials"
            exit 5
        fi
    fi
else
    if sudo docker login && sudo docker push ariitk/$DOCKERREPO:$VERSION ; then
        echo "Push succeeded."
    else 
        echo "Push to Dockerhub failed. Maybe check your internet connection/enter correct credentials"
        exit 5
    fi

    if [ $VERSIONCHECK -eq 0 ] ; then
        echo "Since this is the latest version, also building and pushing image with name ariitk/$DOCKERREPO:latest"
        sudo docker build -t ariitk/$DOCKERREPO:latest .
        if sudo docker login && sudo docker push ariitk/$DOCKERREPO:latest ; then
            echo "Push succeeded."
        else 
            echo "Push to Dockerhub failed. Maybe check your internet connection/enter correct credentials"
            exit 5
        fi
    fi
fi
echo "Commiting the Dockerfile."