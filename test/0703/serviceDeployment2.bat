curl http://localhost:8080
kubectl create -f pod-service-connector.yml
kubectl delete pod service-test-client
kubectl delete service service-test
kubectl delete deployment service-test-deploy
kubectl delete replicaset service-test 