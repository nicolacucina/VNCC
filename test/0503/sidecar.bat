kubectl create -f create-sidecar.yml
kubectl get pods
kubectl describe pod sidecar-pod
PAUSE
kubectl exec -it sidecar-pod -c sidecar -- /bin/bash