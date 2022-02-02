In the directory with the Dockerfile, run:

`docker build -t henholm/rpi-books .`

`docker push henholm/rpi-books`

To run an interactive shell on a container created from the image, you can for example run:

`docker run -v $(pwd):/var/rpi-books -it henholm/rpi-books:latest /bin/bash`