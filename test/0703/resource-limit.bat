kubectl create -f cpu-limit-ns.yml
kubectl get ns
kubectl create -f pod-resource-limit.yml
kubectl get pods
PAUSE
kubectl delete pod frontend
kubectl delete ns cpu-limit