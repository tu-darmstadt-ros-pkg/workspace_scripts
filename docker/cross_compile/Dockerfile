ARG ROS_DISTRO
ARG BASE_IMAGE=ros:${ROS_DISTRO}-ros-base
FROM ${BASE_IMAGE}
# Args are reset after FROM
ARG ROS_DISTRO
ARG USER_ID
ARG GROUP_ID
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=${ROS_DISTRO}

RUN apt-get update && apt-get install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential python3-catkin-tools debconf keyboard-configuration
RUN groupadd --gid $GROUP_ID user && useradd --create-home --no-user-group --uid $USER_ID --gid $GROUP_ID --groups sudo user && \
    echo "user  ALL = NOPASSWD: ALL" >> /etc/sudoers
WORKDIR /workspace
RUN chown $USER_ID:$GROUP_ID /workspace
USER user
RUN rosdep update
ENV SHELL=/bin/bash
COPY cross_compile /usr/bin/cross_compile
ENTRYPOINT [ "/usr/bin/cross_compile" ]
