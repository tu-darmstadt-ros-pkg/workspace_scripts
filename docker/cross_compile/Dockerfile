ARG ROS_DISTRO
FROM ros:${ROS_DISTRO}-ros-base
# Args are reset after FROM
ARG ROS_DISTRO
ARG USER_ID
ARG GROUP_ID
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=${ROS_DISTRO}

RUN apt-get update && apt-get install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential python3-catkin-tools
RUN addgroup --gid $GROUP_ID user
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
WORKDIR /workspace
RUN chown $USER_ID:$GROUP_ID /workspace
USER user
RUN rosdep update
ENV SHELL=/bin/bash
COPY cross_compile /usr/bin/cross_compile
ENTRYPOINT [ "/usr/bin/cross_compile" ]
