# 1-build-docker-image.md

The `Dockerfile` in the root of this repo is an example of a Docker image that can run the Calibre `ebook-convert` necessary to scrape news into `epub`s. To build an image using the `Dockerfile`, you can for example run:

```shell
docker build -t {USERNAME}/{NAME_OF_IMAGE} .
```

where you replace `{USERNAME}` and `{NAME_OF_IMAGE}` with whatever you find suitable.

In my case, I set the image name and tag to `rpi3-debian-calibre:20221014`, where I set the tag, i.e., `20221014`, to equal the tag of the `balenalib/raspberrypi3-debian` base image used in the `Dockerfile`.

You can then push the image to a suitable repository or registry you have configured by running, e.g.:

```shell
docker push {USERNAME}/{NAME_OF_IMAGE}
```

To run an interactive shell on a container created from the image, you can run:

```shell
docker run -v $(pwd):/rpi-news-fetcher -it {USERNAME}/{NAME_OF_IMAGE}:latest /bin/bash
```

assuming that the `WORKDIR` of the Docker container is set to `/rpi-news-fetcher`.

## Note

On my Intel MacBook, I was unable to successfully build the image from the `Dockerfile` when running [Rancher Desktop](https://rancherdesktop.io/), even when (1) specifying and using a multi-arch builder via `docker buildx create` and `docker buildx use`, and (2) running seemingly suitable commands such as `docker buildx build --platform linux/arm/v7 --tag {USERNAME}/{NAME_OF_IMAGE} --push .`. Shutting down Rancher Desktop and starting up [Docker Desktop](https://www.docker.com/products/docker-desktop/) (and its corresponding K8s cluster) instead resolved my issue, in effect allowing me to build the Raspberry Pi-based image on my MacBook.