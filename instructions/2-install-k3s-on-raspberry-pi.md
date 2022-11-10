# 2-install-k3s-on-raspberry-pi.md
## Why K3s?

From the [k3s docs](https://k3s.io/):

> K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.
> K3s is packaged as a single <60MB binary that reduces the dependencies and steps needed to install, run and auto-update a production Kubernetes cluster.
> Both ARM64 and ARMv7 are supported with binaries and multiarch images available for both. K3s works great on something as small as a Raspberry Pi to an AWS a1.4xlarge 32GiB server.

## Raspberry Pi K3s set-up

The below steps draw inspiration from:
- https://medium.com/codex/which-kubernetes-distribution-you-should-install-on-raspberry-pi-27fa9fe1e658
- https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#4-installing-microk8s

### 1. Install K3s using `curl`

On your Raspberry Pi, install K3s with the following command:

```shell
$ curl -sfL https://get.k3s.io | sh -
```

You might get the following error:

```shell
Job for k3s.service failed because the control process exited with error code. See "systemctl status k3s.service" and "journalctl -xe" for details.
```

If you did not get the error, proceed to [the next step](#2-reboot). If you did get the error, add `cgroup_memory=1 cgroup_enable=memory` to the `/boot/cmdline.txt` on :

```shell
$ sudo nano /boot/cmdline.txt
```

Note that `/boot/cmdline.txt` is a single-line file, meaning that you **must not** add a new line to the file when adding `cgroup_memory=1 cgroup_enable=memory` to the config.

The following is what the `/boot/cmdline.txt` file looked like on my Raspberry Pi *before* adding `cgroup_enable=memory cgroup_memory=1`:

```shell
console=serial0,115200 console=tty1 root=PARTUUID=ff993489-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles
```

The following is what it looked like *after* the modification:

```shell
cgroup_enable=memory cgroup_memory=1 console=serial0,115200 console=tty1 root=PARTUUID=ff993489-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles
```

### 2. Reboot

```shell
$ sudo reboot
```

### 3. Modify the permissions of the Kubernetes config file

```shell
$ sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

### 4. See whether the cluster is up and running

A single-node cluster should now be set up and running. Verify that it is by running:

```shell
$ kubectl get node
```