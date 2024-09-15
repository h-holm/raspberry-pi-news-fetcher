# K3s Set-Up

This document outlines how [K3s](https://k3s.io) can be configured on a Raspberry Pi device.

## Why K3s?

From the K3s docs:

> K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances.
>
> K3s is packaged as a single <60MB binary that reduces the dependencies and steps needed to install, run and auto-update a production Kubernetes cluster.
>
> Both ARM64 and ARMv7 are supported with binaries and multiarch images available for both. K3s works great on something as small as a Raspberry Pi to an AWS a1.4xlarge 32GiB server.

## K3s Set-Up

The below steps draw inspiration from:
- https://medium.com/codex/which-kubernetes-distribution-you-should-install-on-raspberry-pi-27fa9fe1e658
- https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#4-installing-microk8s

### 1. Install K3s Using `curl`

On your Raspberry Pi, run the following command:

```shell
$ curl -sfL https://get.k3s.io | sh -
```

You might get the following error:

```shell
Job for k3s.service failed because the control process exited with error code. See "systemctl status k3s.service" and "journalctl -xe" for details.
```

If you did not get the error, proceed to [the next step](#2-prevent-permission-denied-error-when-reading-k3s-config-file-on-start-up). If you did get the error, add `cgroup_memory=1 cgroup_enable=memory` to the `/boot/firmware/cmdline.txt` file on your Raspberry Pi:

```shell
$ sudo nano /boot/firmware/cmdline.txt
```

Note that `/boot/firmware/cmdline.txt` is a single-line file, meaning that you **must not** add a new line to the file when adding `cgroup_memory=1 cgroup_enable=memory` to the config.

The following is what the `/boot/firmware/cmdline.txt` file looked like on my Raspberry Pi *before* adding `cgroup_enable=memory cgroup_memory=1`:

```text
console=serial0,115200 console=tty1 root=PARTUUID=e44d0680-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=SE
```

The following is what it looked like *after* the modification:

```text
cgroup_enable=memory cgroup_memory=1 console=serial0,115200 console=tty1 root=PARTUUID=e44d0680-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=SE
```

After updating the `/boot/firmware/cmdline.txt` file, reboot the Raspberry Pi:

```shell
$ sudo reboot
```

### 2. Prevent `permission denied` Error When Reading K3s Config File on Start-Up

To prevent the following error on reboot of your Raspberry Pi:

```shell
WARN[0000] Unable to read /etc/rancher/k3s/k3s.yaml, please start server with --write-kubeconfig-mode to modify kube config permissions
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
```

add a `K3S_KUBECONFIG_MODE="644"` line to `/etc/systemd/system/k3s.service.env`:

```shell
$ sudo nano /etc/systemd/system/k3s.service.env
...
K3S_KUBECONFIG_MODE="644"
```

An ad-hoc solution would have been to manually adjust the file permissions each time the error is encountered, but that has the drawback of you having to SSH into or otherwise connect to your Raspberry Pi each time it has rebooted. Nevertheless, as it might come in handy at some point, a manual solution (that would not persist after reboot) is the following:

```shell
$ sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

### 3. Reboot

```shell
$ sudo reboot
```

### 4. Verify that Cluster is Up and Running

A single-node cluster should now be set up and running, despite the restart. Verify that it is by running:

```shell
$ kubectl get node
```
