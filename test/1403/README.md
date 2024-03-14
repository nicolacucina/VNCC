# Kubernetes Journey
###### Gianluca Reali

## Introduction
This document shows the implementation and the related usage of a sample Kubernetes Cluster over virtual machines (VMs). In order to make things simple, we just use two VMs, one for implementing the Kubernetes Master, the other for the only Kubernetes worker. Please send any found errors or typos to gianluca.reali@unipg.it 

## Kubernetes Cluster Implementation
### Setup

The first step consists of instantiating two VMs and configure their single interface networking. 

First open Virtualbox and instatiate two VMs by using the provided XUbuntu 22.04.rel 02 ova image, named VNCC-Xubuntu-22-02.ova.

In Virtualbox, using the Tools Tab, create the Kubernetes NAT network, using the following parameters:

    name: kubernetes
    ipv4 prefix: 192.168.43.0/24
    enable dhcp: true

After launching the VMs, in each one edit the file _/etc/netplan/01-network-manager-all.yaml_, configuring the IP addresses 192.168.43.10/24 in the `Controller node` and 192.168.43.11/24 in the `Worker node`, as in the following example:

    network:
    version: 2
    renderer: NetworkManager
    ethernets:
        enp0s3:
            dhcp4: no
            ##Controller node ip
            addresses: [192.168.43.10/24]
            ##Worker node ip
            #addresses: [192.168.43.11/24]
            gateway4: 192.168.43.1
            nameservers: 
                addresses: [8.8.8.8, 8.8.4.4]

To provide compatibility with the other VMs already distributed, in both nodes edit the files _/etc/hostname_ as follows. In the `Controller` node:
    
    controller

while in the `Worker` node:
    
    worker-1

In both nodes, edit the file _/etc/hosts_ including what follows.

    192.168.43.10 controller  controller.example.com
    192.168.43.11 worker-1  worker-1.example.com
    # Ansible inventory hosts BEGIN
    192.168.43.10 controller.provaspray.local controller node1
    192.168.43.11 worker-1.provaspray.local worker-1  node2


### Kubernetes cluster Installation guide through Kubespray

Install ssh server on both nodes.

    sudo apt update
    sudo apt install openssh-server

Generate keyless login for ssh session, necessary for Ansible:

    ssh-keygen -t rsa

Do not type any password otherwise passwordless behavior would be impossible (press Enter three times without typing anything).

Copy the public key of all nodes in all the nodes of the cluster (including the Master node, since Ansible will also ssh connect with the localhost) 
    
    ssh-copy-id 192.168.43.10
    ssh-copy-id 192.168.43.11
     
Modify the file _/etc/sudoers_ (as sudo) for allowing passwordless sudo commands in all nodes.

    ...
    root ALL=(ALL) NOPASSWD: ALL
    studente ALL=(ALL) NOPASSWD: ALL 

Now install python in all nodes

    sudo apt install python3-pip
    sudo pip3 install --upgrade pip

Now you can check if the installation was succesful using
 
    pip --version

#### From now on, only use the `Controller` Node

download `kubespray`. 
    
    sudo apt install git
    git clone https://github.com/kubernetes-sigs/kubespray.git
    cd kubespray
    sudo pip install -r requirements.txt

Now start doing the appropriate configuration (https://github.com/kubernetes-sigs/kubespray)

Copy `inventory/sample` as `inventory/mycluster`

    cp -rfp inventory/sample inventory/mycluster (sample folder for this example)

Update Ansible inventory file with inventory builder:

    declare -a IPS=(192.168.43.10 192.168.43.11)
    CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}

Now review _inventory/mycluster/hosts.yml_ and verify the suitable configuration. By default it will have both nodes inside the kube_control_plane and the kube_node sections, to better isolated the nodes and their roles it should be:

    all:
        hosts:
            node1:
                ## This is the Controller node
                ansible_host: 192.168.43.10
                ip: 192.168.43.10
                access_ip: 192.168.43.10
            node2:
                ## This is the Worker node
                ansible_host: 192.168.43.11
                ip: 192.168.43.11
                access_ip: 192.168.43.11
        children:
            kube_control_plane:
                hosts:
                    node1:
                    #node2
            kube_node:
                hosts:
                    #node1
                    node2:
            etcd:
                hosts:
                    node1:
            k8s_cluster:
                children:
                    kube_control_plane:
                    kube_node:
            calico_rr:
                hosts: {}

Change parameters under `inventory/mycluster/group_vars`, editing the file _inventory/mycluster/group\_vars/all/all.yml_ (infrastructure file) by decommenting the following line:

    upstream_dns_servers:
    - 8.8.8.8
    - 8.8.4.4

Edit the file _inventory/mycluster/group\_vars/k8s-cluster/k8s-cluster.yml_   

    kube_config_dir: /etc/kubernetes
    ...
    kube_network_plugin: calico
    ...
    # Kubernetes internal network for services, unused block of space.
    kube_service_addresses: 10.233.0.0/18
    ...
    # internal network. When used, it will assign IP
    # addresses from this range to individual pods.
    # This network must be unused in your network infrastructure!
    kube_pods_subnet: 172.16.0.0/24
    ...
    kube_network_node_prefix: 24
    ...
    container_manager: containerd
    ...
    resolvconf_mode: host_resolvconf

However, the Pods created with the option hostnetwork: true, that is they use the host network interface, cannot reach the cluster DNS. 

Clean up old Kubernetes cluster with Ansible Playbook.
Run the playbook as `root`, the option `--become` is required to, for example, clean up SSL keys in /etc/, or uninstall old packages and interacting with various systemd daemons.
Without `--become` the playbook will fail to run! `And be mindful it will remove the current kubernetes cluster (if it's running)!`


    ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root reset.yml

Even if we haven't installed Kubernetes yet, do it anyway to check is all connections and configuratios are working 

Now install `Kuberbetes` as follows:

    ansible-playbook -i inventory/mycluster/hosts.yaml  --become --become-user=root cluster.yml

Now install `Kubectl` as follows:
    
    sudo snap install kubectl --classic

Now you can run kubectl as `root` user, but we want to use it as `studente` user:

    sudo cp /etc/Kubernetes/admin.conf /home/studente/config

Optionally, you can make this file `readonly` as best practice however for our experiments it is not needed.

    sudo chmod +r  ~/config


    Go to $HOME
    mkdir .kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

Check if the cluster is actually working:
    
    kubectl get nodes 

### Implementation of a sample Service

Create the following manifest yaml file: 

    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name: nginx
        labels:
        app: proxy
    spec:
        selector:
            matchLabels:
                app: proxy
        template:
            metadata:
                labels: 
                    app: proxy
            spec: 
                containers:
                - name: nginx
                    image: nginx:latest
                    ports:
                        - containerPort: 80
                            name: http-web-svc       
    ---
    apiVersion: v1
    kind: Service
    metadata:
        name: nginx-service
    spec:
        type: NodePort 
        #type: ExternalName
        #externalName: cname.dns
        selector:
            app: proxy
        ports:
        - name: http
            protocol: TCP
            port: 8080
            targetPort: http-web-svc
            nodePort: 30007
        #externalIPs: 
        #- 192.168.1.15
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: nginx-ingress
    spec:
        rules:
        - host: "foo.bar.com"
            http:
                paths:
                - pathType: Prefix
                    path: "/bar"
                    backend:
                        service:
                            name: nginx-service
                            port:
                                number: 80

Deploy it using Kubectl create -f \<filename\> to check if Kubernetes is working properly (this is just an example manifest and is not used later on, any kind of manifest can do).

### HorizontalPODAutoscaler

The first thing to do is the creation of the metric server.

Download the following manifest:

    wget -O components.yaml https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml


Open the file and include the following row:

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        k8s-app: metrics-server
      name: metrics-server
      namespace: kube-system
    spec:
      ...
        spec:
          containers:
          - args:
            - --cert-dir=/tmp
            - --secure-port=10250
            - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
            - --kubelet-use-node-status-port
            - --metric-resolution=15s
            - --kubelet-insecure-tls  #ADD THIS

Now create the metric server, as follows

    Kubectl apply -f ./components.yaml

Check that all Pods are running before continuing

Now we make use of HPA. The professor adapted the documentation available at: 
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

A HorizontalPodAutoscaler (HPA for short) automatically updates a workload resource (such as a Deployment or StatefulSet), with the aim of automatically scaling the workload to match demand.

To demonstrate a HorizontalPodAutoscaler, you will first start a Deployment that runs a container using the `hpa-example` image, and expose it as a Service using the following manifest:

    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name: php-apache
    spec:
        selector:
            matchLabels:
                run: php-apache
        template:
            metadata:
                labels:
                    run: php-apache
            spec:
                containers:
                - name: php-apache
                    image: registry.k8s.io/hpa-example
                    ports:
                    - containerPort: 80
                    resources:
                        limits:
                            cpu: 500m
                        requests:
                            cpu: 200m
    ---
    apiVersion: v1
    kind: Service
    metadata:
        name: php-apache
        labels:
            run: php-apache
    spec:
        ports:
        - port: 80
        selector:
            run: php-apache

Now if the server is running, create the `autoscaler` using the following manifest:

    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    metadata:
        name: php-apache
        namespace: default
    spec:
        maxReplicas: 10
        metrics:
        - resource:
                name: cpu
                target:
                    averageUtilization: 50
                    type: Utilization
            type: Resource
    minReplicas: 1
    scaleTargetRef:
        apiVersion: apps/v1
        kind: Deployment
        name: php-apache

Next, see how the autoscaler reacts to increased load. To do this, you'll start a different Pod to act as a client. The container within the client Pod runs in an infinite loop, sending queries to the php-apache service.

Run this in a `separate terminal` so that the load generation continues and you can carry on with the rest of the steps:

    kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

This command creates a Pod loading the Deployment. Now check the active Pods. You should see the replicas created.

### ADDITIONAL FEATURES:

Modify _group\_vars/k8s-cluster/addons.yml_ to enable the local volume provisioner so persistent volumes can be used and the cert manager to later be able to automatically provision SSL certs using `Let’s Encrypt`:

    local_volume_provisioner_enabled: true
    .
    .
    .
    cert_manager_enabled: true

Inside the same file, you can enable and configure the also metric server.

    # Metrics Server deployment
    metrics_server_enabled: true
    metrics_server_container_port: 10250
    metrics_server_kubelet_insecure_tls: true
    metrics_server_metric_resolution: 15s
    metrics_server_kubelet_preferred_address_types: "InternalIP,ExternalIP,Hostname"
    metrics_server_host_network: false
    metrics_server_replicas: 1


#### For enabling MetalLB:

In the file _inventory/home/group\_vars/k8s\_cluster/k8s-cluster.yaml_

    kube_proxy_strict_arp: true

In the file _inventory/home/group\_vars/k8s_cluster/addons.yml_

    metallb_enabled: true
    metallb_speaker_enabled: true
    .. other nearby parameters are available ...
    # this is range of IPs that is in the same subnet as the k8s nodes
    metallb_ip_range:
        - 192.168.1.200-192.168.1.220

#### Useful Commands

    nmcli device show <interfacename> 

    kubectl api-versions

    kubectl describe pod kube-apiserver -n kube-system

    kubectl port-forward svc/web-servers 8080:80

    kubectl explain pods.spec

    kubectl config current-context kubernetes-admin@provaspray.local

    kubectl get serviceaccounts

    kubectl get endpoints

Use of a load generatori: 

    hey -n 10000 -c 5 http://localhost:8080/

Enalbe IPv4 forwarding: 
    
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

Disable Swap: 
    
    swapoff -a

Other commands:

    kubectl edit configmap -n kube-system kube-proxy

    sudo update-alternatives --config editor

#### OTHER USEFUL LINKS:

https://elatov.github.io/2022/10/using-kubespray-to-install-kubernetes/