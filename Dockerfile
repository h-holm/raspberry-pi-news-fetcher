# FROM navikey/raspbian-bullseye:2022-01-16
# FROM balenalib/raspberrypi3-debian:latest
FROM balenalib/raspberrypi3-debian:6.0.0+balena1-arm
RUN apt-get update
# RUN apt-get -y install zlib1g bzip2 expat sqlite libffi6 openssl ncurses-bin ncurses-base readline-common python python-setuptools python-six python-cssutils python-dateutil python-dnspython python-mechanize python-regex python-chardet python-msgpack python-pygments python-pycryptopp python-apsw libicu63  nasm cmake libjpeg-turbo-progs libpng-tools libwebp6 libjxr-tools libfreetype6 fontconfig python-libxml2 python-libxslt1 python-lxml python-webencodings python-html5lib python-pillow python-netifaces python-psutil python-chm python-poppler libgpg-error0 libgcrypt20 libglib2.0-0 python-dbus libdbus-1-3 dbus python-pyqt5 python-sip python-pyqt5.qtwebkit optipng libusb-1.0-0 libmtp-common pkg-config qt5-qmake qt5-default pyqt5-dev libglib2.0-dev python-fontconfig libfontconfig1-dev g++ python-dev libssl-dev libicu-dev libsqlite3-dev libchm-dev libpodofo-dev python-sip-dev qtbase5-private-dev libusb-1.0-0-dev libmtp-dev libmtdev-dev libxml2-dev libxslt1-dev python-pip pyqt4-dev-tools libqt4-dev-bin make wget patch gawk ca-certificates xz-utils libcurl4-openssl-dev curl
RUN apt-get -y install calibre
WORKDIR "/books"
COPY ./economist.recipe ./
CMD ["ebook-convert", "economist.recipe", "economist.epub"]