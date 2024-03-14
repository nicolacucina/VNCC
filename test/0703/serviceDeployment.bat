kubectl apply -f service-deployment.yml
PAUSE # dargli tempo
kubectl port-forward service/service-test 8811:80