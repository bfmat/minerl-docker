FROM nvidia/cuda:9.0-base

# Install some basic utilities and Java for Minecraft
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    tmux \
    htop \
    gcc \
    xvfb \
    python-opengl \
    x11-xserver-utils \
    openjdk-8-jdk \
 && rm -rf /var/lib/apt/lists/*

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda
RUN curl -so ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh
ENV PATH=/home/user/miniconda/bin:$PATH
ENV CONDA_AUTO_UPDATE_CONDA=false

# Create a Python 3.6 environment
RUN /home/user/miniconda/bin/conda install conda-build \
 && /home/user/miniconda/bin/conda create -y --name py36 python=3.6 \
 && /home/user/miniconda/bin/conda clean -ya
ENV CONDA_DEFAULT_ENV=py36
ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
ENV PATH=$CONDA_PREFIX/bin:$PATH

# TensorFlow with CUDA 9.0 installation
RUN conda install -y cudatoolkit=9.0 tensorflow-gpu=1.12 matplotlib pandas jupyter jupyterlab scikit-learn
RUN conda clean -ya

# Install MineRL
RUN pip install --upgrade --user minerl

# Create starting file
RUN echo "xhost + & jupyter notebook --allow-root --ip 0.0.0.0" > /app/xvfb.sh
RUN echo "xvfb-run -s \"-screen 0 1400x900x24\" /app/xvfb.sh" > /app/run.sh
RUN chmod ugo+x /app/xvfb.sh
RUN chmod ugo+x /app/run.sh

# Set the default command to jupyter
CMD ["sh", "/app/run.sh"]
