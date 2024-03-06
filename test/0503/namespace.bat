kubectl create -f app-ns.yml
kubectl get namespaces
kubectl describe namespace app-ns
kubectl get pods --namespace=app-ns
PAUSE
kubectl delete namespace app-ns