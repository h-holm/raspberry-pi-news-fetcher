# Kubernetes (K8s) Cron Job Set-Up

This document outlines how a [K8s CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs) based on the [../news_fetcher_k8s_cronjob.yml](../news_fetcher_k8s_cronjob.yml) can be configured.

## Creating the K8s CronJob

```shell
$ kubectl apply -f news_fetcher_k8s_cronjob.yml
```

**That is all you need to do. The rest is optional.**

## Getting Info About the Running K8s CronJob

Note that the name 'news-fetcher' is given in the yml-file used to create the CronJob.

```shell
$ kubectl get cronjob news-fetcher
```

## Deleting the CronJob

```shell
$ kubectl delete cronjob news-fetcher
```

## Instantiating a Job From the CronJob On Demand

If you want to test the CronJob right away without waiting until the next scheduled run, instantiate a Job from the running CronJob with the following command:

```shell
$ kubectl create job ${NAME_OF_TEST_JOB} --from=cronjob/news-fetcher
```

### Getting Info About the New Job

```shell
$ kubectl get job ${NAME_OF_TEST_JOB}
```

### Checking the Logs of a Running Job

To see the logs of the running Job, first find the name of the pod it is running on:

```shell
$ kubectl get pods
```

The output might contain something like the following:

```shell
${NAME_OF_TEST_JOB}--1-7g2fz
```

Output the logs of the identified pod by running, e.g.:

```shell
$ kubectl logs ${NAME_OF_TEST_JOB}--1-7g2fz
```

### Deleting the Job

```shell
$ kubectl delete job ${NAME_OF_TEST_JOB}--1-7g2fz
```
