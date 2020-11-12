FROM dorowu/ubuntu-desktop-lxde-vnc:latest

RUN  apt-get update \
  && apt-get install -y wget \
  && apt-get install -y unzip

# Setup IB TWS
RUN mkdir -p /opt/TWS
WORKDIR /opt/TWS
RUN wget -q http://cdn.quantconnect.com/interactive/ibgateway-latest-standalone-linux-x64-v974.4g.sh
RUN chmod a+x ibgateway-latest-standalone-linux-x64-v974.4g.sh

# Setup IBController
RUN mkdir -p /opt/IBController/ && mkdir -p /opt/IBController/Logs
WORKDIR /opt/IBController/
RUN wget -q http://cdn.quantconnect.com/interactive/IBController-QuantConnect-3.2.0.5.zip
RUN unzip ./IBController-QuantConnect-3.2.0.5.zip
RUN chmod -R u+x *.sh && chmod -R u+x Scripts/*.sh

WORKDIR /

# Install TWS
RUN yes n | /opt/TWS/ibgateway-latest-standalone-linux-x64-v974.4g.sh

# Below files copied during build to enable operation without volume mount
COPY ./IBController.ini /root/IBController/IBController.ini
COPY ./jts.ini /root/Jts/jts.ini

# Install miniconda
ENV CONDA="Miniconda3-4.5.12-Linux-x86_64.sh"
ENV PATH="${PATH}:/opt/miniconda3/bin"
RUN wget https://cdn.quantconnect.com/miniconda/${CONDA} && \
    bash ${CONDA} -b -p /opt/miniconda3 && rm -rf ${CONDA} && \
    ln -s /opt/miniconda3/lib/libpython3.6m.so /usr/lib/libpython3.6m.so

# Install supported third party python packages
# Updates conda and pip
RUN conda update -y conda pip

# Updates pip
RUN pip install --upgrade pip

# Install essential packages
RUN conda install -y                \
    cython=0.29.15                  \
    numpy=1.18.1                    \
    pandas=0.25.3                   \
    matplotlib=3.2.1                \
    wrapt=1.12.1					\
    setuptools

RUN conda install -y -c conda-forge \
    jupyterlab=2.1.0

# copy runscript
COPY ./runscript.sh /opt/runscript.sh
RUN chmod +x /opt/runscript.sh

# copy Jupyter config
COPY ./jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py

# Install IB API
RUN wget https://interactivebrokers.github.io/downloads/twsapi_macunix.976.01.zip && \
	unzip ./twsapi_macunix.976.01.zip && \
	cd ./IBJts/source/pythonclient && \
	/opt/miniconda3/bin/python setup.py sdist && \
	/opt/miniconda3/bin/python -m pip install --upgrade dist/ibapi-9.76.1.tar.gz

RUN pip install ib_insync