FROM osrf/ros:humble-desktop

# Build-time args (preserved for compatibility with other Dockerfiles)
ARG USER_ID
ARG GROUP_ID

# Run everything as root to simplify usage inside the container
ENV DEBIAN_FRONTEND=noninteractive \
	LANG=en_US.UTF-8 \
	LC_ALL=en_US.UTF-8 \
	HOME=/root \
	ROS_DISTRO=humble

WORKDIR /root

# Install essential build tools and ROS helpers
RUN apt-get update && apt-get install -y --no-install-recommends \
	lsb-release \
	gnupg \
	curl \
	wget \
	build-essential \
	python3-pip \
	python3-rosdep \
	python3-colcon-common-extensions \
	python3-rosinstall \
	python3-rosinstall-generator \
	python3-vcstool \
	locales \
	git \
	&& locale-gen en_US.UTF-8 \
	&& update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
	&& rm -rf /var/lib/apt/lists/*

# Prepare rosdep (may be a no-op if already initialized)
RUN rosdep init || true

# Create ROS2 workspace and copy local packages into it (place packages in build-context ./src/)
RUN mkdir -p /root/ros2_ws/src
COPY src/ /root/ros2_ws/src/
WORKDIR /root/ros2_ws

# Install package dependencies and build the workspace in the same RUN so environment is available
RUN apt-get update && \
	rosdep update && \
	rosdep install -i --from-paths src --rosdistro ${ROS_DISTRO} -y || true && \
	# If packages provide requirements.txt, install them (useful for Python-only deps)
	for f in $(find src -type f -name 'requirements.txt' 2>/dev/null); do \
		echo "Installing pip requirements from $f"; \
		pip3 install -r "$f" || true; \
	done && \
	# Build workspace (source ROS in the same shell)
	/bin/bash -lc "source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build --symlink-install" && \
	rm -rf /var/lib/apt/lists/*

# Make workspace and ROS available in interactive shells
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /root/.bashrc \
	&& echo "source /root/ros2_ws/install/local_setup.bash" >> /root/.bashrc \
	&& echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> /root/.bashrc \
	&& echo "export _colcon_cd_root=/opt/ros/${ROS_DISTRO}/" >> /root/.bashrc \
	&& echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> /root/.bashrc

WORKDIR /root
CMD ["/bin/bash"]
