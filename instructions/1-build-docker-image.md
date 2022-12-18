# 1-build-docker-image.md

> Feel free to use the [public Docker image](https://hub.docker.com/repository/docker/henholm/raspberry-pi-news-fetcher) I build and maintain, in which case you can disregard the instructions below. You use the Docker image in your [K8s CronJob](../fetch_news_k8s_cronjob.yml) by specifying, e.g., `henholm/raspberry-pi-news-fetcher:latest` in the `image` field of the [K8s CronJob config](../fetch_news_k8s_cronjob.yml). This should be the default when you pull down this repo.

The [Dockerfile](../Dockerfile) in the root of this repo is an example of a Docker image that can run the Calibre `ebook-convert` command that is necessary to scrape news into `epub`s.

In my case, I set up CI using [GitHub Actions](https://docs.github.com/en/actions) to automatically build and push a Docker image from the [Dockerfile](../Dockerfile) on push to or merge into the `main` branch (see the [../.github/workflows/ci.yml](../.github/workflows/ci.yml) file for details).

To avoid storing the Docker Hub access token generated for the CI in cleartext, I configure [repository secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) in the GitHub web UI.

If you would like to manually build and push an image from the [Dockerfile](../Dockerfile), however, you can of course do that. For example, you could run:

```shell
$ docker build -t {USERNAME}/{NAME_OF_IMAGE}:{TAG} -t {USERNAME}/{NAME_OF_IMAGE}:latest .
$ docker push {USERNAME}/{NAME_OF_IMAGE}
```

where you replace `{USERNAME}`, `{NAME_OF_IMAGE}` and `{TAG}` with whatever you find suitable, and assuming you run the command from the root of the repo.

To run an interactive shell on a container created from the image, you can run:

```shell
$ docker run --platform linux/arm/v7 -v $(pwd):/app -it {USERNAME}/{NAME_OF_IMAGE}:latest /bin/bash
```

assuming that the `WORKDIR` of the Docker container is set to `/app`.

## Note

On my Intel MacBook, when manually building the image (i.e., without using CI), I was unable to successfully build the image from the [Dockerfile](../Dockerfile) when running [Rancher Desktop](https://rancherdesktop.io/), even when (1) specifying and using a multi-arch builder via `docker buildx create` and `docker buildx use`, and (2) running seemingly suitable commands such as `docker buildx build --platform linux/arm/v7 --tag {USERNAME}/{NAME_OF_IMAGE} --push .`. Shutting down Rancher Desktop and instead starting up [Docker Desktop](https://www.docker.com/products/docker-desktop/) (and its corresponding K8s cluster) resolved my issue, in effect allowing me to build the Raspberry Pi-based image on my MacBook.