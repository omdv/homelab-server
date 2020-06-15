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

# runscript
COPY ./runscript.sh /opt/runscript.sh
RUN chmod +x /opt/runscript.sh

## Launch IBController
#CMD bash /opt/runscript.sh