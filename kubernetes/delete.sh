#!bin/sh

export CURRENT_PROJECT=$(gcloud config list | grep "project =" | cut -c 11-)

echo "Do you really want delete $CURRENT_PROJECT? [y/N]"
read ans

if [[ $ans = "y" ]]; then
  echo "Destroying cluster..."
  sleep 2

  kubectl delete -f ./kubernetes/mysql-persistent-volume.yaml
  kubectl delete -f ./kubernetes/mysql-persistent-volume-claim.yaml

  kubectl delete -f ./kubernetes/web-deployment.yaml
  kubectl delete -f ./kubernetes/web-service.yaml
  kubectl delete -f ./kubernetes/mysql-deployment.yaml
  kubectl delete -f ./kubernetes/mysql-service.yaml

  # kubectl delete -f ./kubernetes/secret.yaml
fi
