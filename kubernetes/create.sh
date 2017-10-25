#!bin/sh
#Example:
#ENV_PASSWORD=secretpassword sh kubernetes/create.sh


if [[ "$ENV_PASS" = "" ]]; then
  echo "You must set the ENV_PASS password first. Example:\ENV_PASS=<PASSWORD> sh kubernetes/create.sh"
  # exit
else
  # Now we decrypt the environment variables
  openssl enc -aes-256-cbc -salt -d -in kubernetes/secret.yaml.enc -out kubernetes/secret.yaml.tmp -k $ENV_PASS
  export CURRENT_PROJECT=$(gcloud config list | grep "project =" | cut -c 11- | base64)
  sed "s;ZGVmYXVsdGluaXQ=;$CURRENT_PROJECT;g" kubernetes/secret.yaml.tmp > kubernetes/secret.yaml
  rm kubernetes/secret.yaml.tmp
  # Run the opposite command if you want to modify the secrets:
  # openssl enc -aes-256-cbc -salt -in secret.yaml -out secret.yaml.enc -k $ENV_PASS
fi

# kubectl create -f ./kubernetes/storage-class.yaml

# kubectl create -f ./kubernetes/mysql-persistent-volume.yaml
kubectl create -f ./kubernetes/mysql-persistent-volume-claim.yaml
# kubectl create -f ./kubernetes/mysql-persistent-volume-claim-ebs.yaml

# kubectl create -f ./kubernetes/prestashop-persistent-volume.yaml
kubectl create -f ./kubernetes/prestashop-persistent-volume-claim.yaml
# kubectl create -f ./kubernetes/prestashop-persistent-volume-claim-ebs.yaml

kubectl create -f ./kubernetes/mysql-deployment.yaml
kubectl create -f ./kubernetes/mysql-service.yaml
kubectl create -f ./kubernetes/web-deployment.yaml
kubectl create -f ./kubernetes/web-service.yaml

# kubectl create -f ./kubernetes/secret.yaml
