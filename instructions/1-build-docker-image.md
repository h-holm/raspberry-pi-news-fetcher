# Building of Container Image

The [K8s CronJob manifest](../news_fetcher_k8s_cronjob.yml) needs to run a container bundled with the [Calibre command-line interface](https://manual.calibre-ebook.com/generated/en/cli-index.html). This document outlines how such an image can be built.

> NOTE: feel free to use the [container image](https://hub.docker.com/repository/docker/henholm/raspberry-pi-news-fetcher) I build and maintain, in which case you can disregard the instructions below.

The [Dockerfile](../Dockerfile) is an example of a Raspbian Bullseye-compatible Docker image that can run the Calibre `ebook-convert` command. Using a [GitHub Actions workflow](../.github/workflows/build-and-push-image.yml), this repo automatically builds and pushes the image on push to the `main` branch.

If you would like to manually build an image from the [Dockerfile](../Dockerfile) and push it to [Docker Hub](https://hub.docker.com), you can of course do so. For instance, you could run:

```shell
$ docker build -t ${DOCKERHUB_USERNAME}/${NAME_OF_IMAGE}:${TAG} .
$ docker push ${DOCKERHUB_USERNAME}/${NAME_OF_IMAGE}
```

To run an interactive shell on a container created from the image, you can run:

```shell
$ docker run --platform linux/arm/v7 -v $(pwd):/app -it ${DOCKERHUB_USERNAME}/${NAME_OF_IMAGE}:${TAG} /bin/bash
```

assuming that the `WORKDIR` of the Docker container is set to `/app`.

## Note

On my Intel MacBook, when manually building the image (i.e., without using CI), I was unable to successfully build the image from the Dockerfile when running [Rancher Desktop](https://rancherdesktop.io/), even when (1) specifying and using a multi-arch builder via `docker buildx create` and `docker buildx use`, and (2) running seemingly suitable commands such as `docker buildx build --platform linux/arm/v7 --tag {USERNAME}/{NAME_OF_IMAGE} --push .`. Shutting down Rancher Desktop and instead starting up [Docker Desktop](https://www.docker.com/products/docker-desktop/) (and its corresponding K8s cluster) resolved my issue, in effect allowing me to build the Raspberry Pi-based image on my MacBook.