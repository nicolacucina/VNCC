kubectl create -f nginx-pod.yaml
kubectl describe pod nginx-pod
PAUSE
kubectl port-forward pods/nginx-pod 8080:80
