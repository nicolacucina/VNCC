# DaemonSet

Pods defined this way are executed inside all nodes of a cluster

# CronJob

# Deployment

Here the manifest file referenced is not local, it's downloaded from an external source

# Service

The Service is a Kubernetes objest used to provide a stable access point that users can utilize from the outside.
Both the app logic and the Service are defined inside the same manifest file, Service uses a `selector` to match the labels of the Pods it manages. The `ports` section binds the internal ports of each Pod to a single port offered by the Service, but it is still `internal` to Kubernetes, to make the service available from the outside we can use the command:

_kubectl port-forwarding service/_ __serviceName__ __ExternalPort__:__InternalPort__, give the service time to initialize everything before launching this command, if the output is:
    _Forwarding from_ 127.0.0.1:__ExternalPort__ -> 8080
    _Forwarding from_ [::1]:__ExternalPort__ -> 8080

If another pod wants to use the services provided by the pods managed by the Service, the internal DNS of Kubernetes allows the use of pods names instead of their internal IP

# Dashboard

Instead of monitoring kubernetes through the terminal, we can use a web page to do that

_kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml_ deployes the dashboard using a manifest provided by Kubernetes

To access the data we need to have admin permissions, this is done by using two manifest files offered by kubernetes, that create an admin user inside the dashboard namespace and binding it to the admin of the dashboard

_kubectl apply -f adminUser.yml_ , _kubectl apply -f serviceAccount.yml_

After deploying these files, we can get an access token by using:

_kubectl -n kubernetes-dashboard create token admin-user_ 

The token will be used to log inside the dashboard. To access the dashboard, it must be enabled using:

_kubectl proxy_ which makes the service available at http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
