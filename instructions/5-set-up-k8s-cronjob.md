### 1. Set up K8s CronJob for fetching news.

`kubectl create -f fetch-news-k8s-cron-job.yml`

That's all you need to do. The rest is optional:

### Get info about the running K8s CronJob. Note that the name 'fetch-news' is given in the yml-file used to create the CronJob.

`kubectl get cronjob fetch-news`

### Delete the CronJob.

`kubectl delete cronjob fetch-news`

### If you want to test the CronJob right now without having to reschedule, you can instantiate a Job from the running CronJob:

`kubectl create job name-of-test-job --from=cronjob/fetch-news`

### Get info about the new job.

`kubectl get job name-of-test-job`

### If you wanna check the logs of the running job, first find the name of the pod it's running on.

`kubectl get pods`

Might give you the following:

`name-of-test-job--1-7g2fz`

### Now to get the logs of the identified pod:

`kubectl logs -f -n default name-of-test-job--1-7g2fz`

### Delete the Job like you delete a CronJob, basically:

`kubectl delete job name-of-test-job--1-7g2fz`