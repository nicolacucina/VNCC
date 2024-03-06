# Creating a single Container

Using a simple manifest contained in the .yaml file, we can deploy a web server using a nginx instance using: 

_kubectl create -f_ __fileManifest__._yaml_ which creates the pod as indicated in the manifest

_kubectl describe pod_ __name__ , _kubectl describe pod_ __name__ or _kubectl get pods -o wide_ can used to check if the deployment was successful, __name__ references the name assinged to the pod either in the `metadata` or the `specs` section, usually its best to use the same name to avoid confusion

In the manifest we only specified the port 80 which is `internal to Kubernetes`, it is not accessible from the outside, this can be fixed at runtime without taking down the pod using:

_kubectl port-forward pods/_ __name__ _8080:80_

The pod can be closed using:

_kubectl delete pod_ __nginx-pod__

# Namespaces

These are used to separate resources and enviroments within a single Kubernetes cluster.
We can get a list of the default namespaces using:

_kubectl get ns --all-namespaces_

A custom namespace can be created using a manifest file:

_kubectl create -f_ __fileManifest__._yml_

A namespace can be deleted using:

_kubectl delete namespace __app-ns__


# Creating multiple Containers inside a sigle Pod

Here we have two Containers, one represents the logic of the application, while the other handles logging information. The pod is created using:

_kubectl create -f_ __fileManifest__._yml_ , where the two Containers are defined, they both are mounted using the same volume, here called `logs`, initialized to an empty volume (which is destroyed when the pod is taken down, usually volumes are permanent but `emptyDir` behaves this way)

As defined inside the manifest, the __app__ Container is saving the `date` variable inside the `date.txt` file, we want to use the __sidecar__ Container to access the file

_kubectl exec -it_ __PodName__ _-c_ __ContainerName__ -- /bin/bash_ , where :
- `exec` is telling the pod to execute a command, 
- `-it` are flags used when we want an interactive shell or terminal (like SSH), ,
- `-c` specifies the different Container inside the Pod,
- `--` separates the arguments for the command from the kubectl parameters

When the shell is opened, we run:

_curl http://localhost/date.txt_ to check the contents of the file

_exit_ closes the session

# Jobs

These are used to execute the logic contained inside the Container a fixed amount of times, specified inside `spec`:
- `completions` is the total amount of times the codes needs to be executed,
- `parallelism` indicates the number of paraller workers that are gonna be used to accellerate the computation
- `restartPolicy` what happens in case the Container experiences an error or fault

_kubectl get jobs_ shows the jobs that Kubernetes is handling, how many times it has already completed, how much time it took and how much time has elapsed since the job has finished

# ReplicaSet

These can be used to scale automatically the app using more replicas that can be dinamically created and destroyed. Inside the `spec` we need to specify:
- `replicas` is the maximem number of replicas
- `selector` this is used to match containers to the ReplicaSet
- `template` is the container that needs to be replicated

_kubectl create -f_ __FileManifest__._yml_

If the number of replicas needs to be changed dinamically without taking down the Pod we can use:

_kubectl scale rc __ReplicaSet__ --replicas=_ __NumReplicas__

ReplicaSet and ReplicationController differ in how they match the labels of the Pod they manage:
- ReplicationController only allow matches to pods that include a certain label (the label specified in the `selector` of the ReplicationController must match the label inside the template of the Containers it manages)
- ReplicaSet extends this mechanism to match pods that lack a certain label or pods that include a certain label key, regardless of its value, using the keywords `In` and `NotIn` for matchings based on values, `Exists` and `DoesNotExist`