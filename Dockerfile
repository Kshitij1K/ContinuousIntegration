FROM ros:melodic-ros-core-bionic

RUN apt-get update && apt-get install -y python-catkin-tools build-essential git python-wstool