Mainly: https://medium.com/codex/which-kubernetes-distribution-you-should-install-on-raspberry-pi-27fa9fe1e658

Also: https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#4-installing-microk8s

K3s is a certified Kubernetes distribution built for IoT & Edge computing. It’s very lightweight and is optimized for ARM, both arm64 and armv7.

Note: k3s replaces a few components used by traditional K8s cluster. Particularly, etcd is replaced with sqlite3 for state management and etc. This won’t affect our daily use though.

### 1. Install K3s using `curl`:

`curl -sfL https://get.k3s.io | sh -`

You might get the following error:

> Job for k3s.service failed because the control process exited with error code.
> See "systemctl status k3s.service" and "journalctl -xe" for details.

#### 1.(1) If you got the error, add `cgroup_memory=1 cgroup_enable=memory` at the end of `cmdline.txt`:

`sudo nano /boot/cmdline.txt`

`cgroup_enable=memory cgroup_memory=1`

Note: `cmdline.txt` is just a file of single line, do not start a new line to append this value.

What the `cmdline.txt`looked like on my particular Raspberry PI before adding `cgroup_enable=memory cgroup_memory=1`:

`console=serial0,115200 console=tty1 root=PARTUUID=ff993489-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles`

And what it looked like after the modification:

`cgroup_enable=memory cgroup_memory=1 console=serial0,115200 console=tty1 root=PARTUUID=ff993489-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles`

### 2. Reboot

`sudo reboot`

### 3. Give permissions to Kubernetes config file:

`sudo chmod 644 /etc/rancher/k3s/k3s.yaml`

### You should now have a single node cluster set up and running. Test it by running:

`kubectl get node`