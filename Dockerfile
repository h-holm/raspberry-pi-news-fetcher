# syntax=docker/dockerfile:1
FROM balenalib/raspberrypi4-64-ubuntu:20240830

WORKDIR /app

COPY ./scripts/fetch_news.sh .

RUN DEBIAN_FRONTEND="noninteractive" TZ="Europe/Stockholm" apt-get update && apt-get -y install \
  tzdata \
  calibre \
  && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "fetch_news.sh" ]
CMD [ "--help" ]
