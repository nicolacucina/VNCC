kubectl create -f replication-controller.yml
kubectl get replicationcontrollers
kubectl scale rc my-apprc --replicas=6
kubectl get replicationcontrollers
kubectl delete replicationcontroller my-apprc