kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl apply -f serviceAccount.yml
kubectl apply -f adminUser.yml
kubectl -n kubernetes-dashboard create token admin-user
# copy token
kubectl proxy 
# url for dashboard: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/