FROM balenalib/raspberrypi3-debian:20240429
RUN apt-get update
RUN apt-get -y install calibre
WORKDIR /app
