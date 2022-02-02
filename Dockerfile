FROM balenalib/raspberrypi3-debian:20220112
RUN apt-get update
RUN apt-get -y install calibre
WORKDIR "/var/rpi-books"