kubectl create -f pod-cronjob.yml
kubectl get jobs --watch
PAUSE
kubectl delete cronjob pod-cronjob