FROM ros:melodic-ros-core-bionic

RUN apt-get update && apt-get install -y python-catkin-tools
RUN apt-get update && sudo apt-get install -y build-essential
# RUN [ "/bin/bash", "-c", "source /opt/ros/melodic/setup.bash" ]
# RUN apt-get install -y nano