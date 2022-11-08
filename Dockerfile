FROM balenalib/raspberrypi3-debian:20221014
RUN apt-get update
RUN apt-get -y install calibre
WORKDIR /rpi-news-fetcher