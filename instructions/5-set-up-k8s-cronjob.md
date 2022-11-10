# 5-set-up-k8s-cronjob.md

## Creating the K8s CronJob

```shell
$ kubectl create -f fetch_news_k8s_cronjob.yml
```

That's all you need to do. The rest is optional.

## Getting info about the running K8s CronJob

Note that the name 'fetch-news' is given in the yml-file used to create the CronJob.

```shell
$ kubectl get cronjob fetch-news
```

## Deleting the CronJob

```shell
$ kubectl delete cronjob fetch-news
```

## Instantiating a Job from the CronJob on demand

If you want to test the CronJob right now without having to reschedule, you can instantiate a Job from the running CronJob with the following command:

```shell
$ kubectl create job NAME-OF-TEST-JOB --from=cronjob/fetch-news
```

### Getting info about the new Job

```shell
$ kubectl get job NAME-OF-TEST-JOB
```

### Checking the logs of a running Job

To see the logs of the running Job, first find the name of the pod it's running on:

```shell
$ kubectl get pods
```

The output might containg something like the following:

```shell
NAME-OF-TEST-JOB--1-7g2fz
```

Output the logs of the identified pod by running, e.g.:

```shell
$ kubectl logs -f -n default NAME-OF-TEST-JOB--1-7g2fz
```

### Deleting the Job

Deleting the Job is identical to deleting a CronJob (or basically any other K8s object):

```shell
$ kubectl delete job NAME-OF-TEST-JOB--1-7g2fz
```