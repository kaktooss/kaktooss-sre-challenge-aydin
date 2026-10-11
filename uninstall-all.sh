
# Delete Apps
helm uninstall back-app -n demo-back
helm uninstall front-app -n demo-front
helm uninstall reader-app -n demo-reader

# Delete Kafka
helm uninstall kafka -n kafka
kubectl delete pvc -l app.kubernetes.io/instance=kafka -n kafka

# Delete Postgresql
helm uninstall postgres -n postgres
kubectl delete pvc -l app.kubernetes.io/instance=postgres -n postgres