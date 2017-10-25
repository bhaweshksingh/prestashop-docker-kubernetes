# Prestashop + Docker Compose + Kubernetes

This repo contains everything necessary to run an e-commerce with Prestashop using docker-compose and to upload it to your own servers using Kubernetes.


## Setup your Kubernetes server

If you want to upload this Prestashop to your own servers using Kubernetes, you need to setup a new cluster first.

If you want to start locally, you can skip this section and do it later.

Checkout the cluster-setup procedure here:  
**TODO**: link to the k8s setup repo.

In particular, this Prestashop project needs to be accompained by two disks. They are to be called `mysql-data` and `prestashop-data` and have at least 10GB of space (this is explained in the previous docs). These disks will be responsible for keeping your data from disappearing.


## How to create and restore the database

We start by building the 'database' container using `docker-compose build database`.

Make sure you set a personal password for both `DB_PASSWD` and `MYSQL_ROOT_PASSWORD` instead of the default value 'P15Oe4EP9gziWzOY4mD' used in this example.

**Pro tip**: You can use .env and k8s secrets to hide your private values like passwords and admin usernames.

Make sure you are running mysql with `docker-compose up database`.

```bash
# To access the database locally run:
docker exec -it yourwebsite_database_1 /bin/bash
# or something like 'kubectl exec -it database-1752311019-2crsq -c database bash' for Kubernetes
# or even better: 'mp k ssh -c database' if you're using the MisPistachos CLI.

# Inside the container run:  
mysql -p
# paste the password: P15Oe4EP9gziWzOY4mD
# Inside mysql run:  
CREATE DATABASE prestashop;
# if you are re-installing, drop your table with: DROP DATABASE prestashop;
# Now you can 'exit'

# RESTORE
# If you are restoring a database you can download a file with your exported database using:
apt-get update -y && apt-get install wget -y
wget https://www.dropbox.com/s/nrn98w1234vx76/yourwebsite_bd.sql
mysql -u root -p<password> prestashop < yourwebsite_bd.sql
# replace <password> for the password: P15Oe4EP9gziWzOY4mD

# Now you can 'exit' again
```


## Steps for a fresh install

We'll start by building the 'web' container using `docker-compose build web`.

After a fresh install, you need to delete the 'install' folder and rename your admin folder.

```bash
# On your console run:
docker exec -it yourwebsite_web_1 /bin/bash

# Inside the container run:  
rm -r install/
mv admin/ admin-yourwebsite
# or use somethin rando like 'admin1229qdvahf'

# You now want to commit these changes to the image, in order to upload them later.
# Exit the container or open another terminal tab. Then follow this example.
$ docker ps

CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS              NAMES
c3f279d17e0a        ubuntu:12.04        /bin/bash           7 days ago          Up 25 hours                            desperate_dubinsky
197387f1b436        ubuntu:12.04        /bin/bash           7 days ago          Up 25 hours                            focused_hamilton

$ docker commit c3f279d17e0a  svendowideit/testimage:version3

f5283438590d

$ docker images

REPOSITORY                        TAG                 ID                  CREATED             SIZE
svendowideit/testimage            version3            f5283438590d        16 seconds ago      335.7 MB
```

Once this is done, lift your server using `docker-compose up web` and access your new website on 'localhost:8080'.


## Steps for importing an existing e-commerce

If you want to transfer an existing e-commerce and not start from scratch, there are certains step to follow.

1. Backup your site (only the 'public_html' folder).
2. Export all mysql data from your old Host in sql format (you get a yourwebsite_bd.sql file).
3. Copy all your 'public_html' files into the 'web/public_html' folder in this repository.
4. Comment the `(OPTION 1)` on the Dockerfile and uncomment the `(OPTION 2)`.
5. (Optional: You can do this step later)   
Edit the 'settings.inc.php' file in the 'web/public_html/config' folder and add your new credentials. You can find the default values in 'web/config_files/settings.inc.php'.
6. Build the 'web' container using `docker-compose build web`. This should take a while.
8. Once this is done, lift your server using `docker-compose up web` and access your new website on 'localhost:8080'.

More info on hosts, exports and imports: https://www.squirrelhosting.co.uk/hosting-blog/hosting-blog-info.php?id=27

### Final configuration before uploading

For your image to work in production, you need to update some permissions and some files and commit these changes to your image before uploading it to gcr.io.

```bash
# On your console run:
docker exec -it yourwebsite_web_1 /bin/bash

# WHAT TO DO IF YOU SKIPPED STEP 5
# What you have to do if you skipped step 5 in the first list is to add the database credentials to the 'config/settings.inc.php' file. Remember you can find the default values in 'web/config_files/settings.inc.php'.

# In the web container install a text editor
apt-get update -y && apt-get install nano -y
nano config/settings.inc.php
# or you can modify this file in your public_html folder before building by not skipping step 5.
# END EXTRA STEPS FOR STEP 5

# To habilitate cache permissions on the machine you need to run
chmod -R 777 cache/
chmod -R 777 config/xml/

# You now want to commit these changes to the image, in order to upload them later.
# Exit the container or open another terminal tab. Then follow this example.
$ docker ps

CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS              NAMES
c3f279d17e0a        ubuntu:12.04        /bin/bash           7 days ago          Up 25 hours                            desperate_dubinsky
197387f1b436        ubuntu:12.04        /bin/bash           7 days ago          Up 25 hours                            focused_hamilton

$ docker commit c3f279d17e0a  svendowideit/testimage:version3

f5283438590d

$ docker images

REPOSITORY                        TAG                 ID                  CREATED             SIZE
svendowideit/testimage            version3            f5283438590d        16 seconds ago      335.7 MB
```

### Uploading your built image to k8s

```bash
# Tag your image using the Google Cloud id and name
docker tag 61a449226d344 gcr.io/your_project_id/your_project_name:1.0
# Upload this image to the image repository gcr.io
gcloud docker -- push gcr.io/your_project_id/your_project_name:1.0
# Now you can change the version of the running 'web' Pod
kubectl set image deployment/web web=gcr.io/your_project_id/your_project_name:1.0
# You can also update the deployment file and then deploy the 'web' Pod inside Kubernetes
kubectl create -f ./kubernetes/web-deployment.yaml
# If necessary, drop the pod and upload it with a new version using:
kubectl delete -f ./kubernetes/web-deployment.yaml
```

### Extra import steps for production:

In local, your files are copied directly from the public_html folder in your repo to your /var/www/html folder in your 'web' container. As these folders are linked, there is no need for this extra step.

But in production, the 'modules', 'override', 'themes' and 'img' folders are empty at first (because they are loaded in external volumes). We need to populate the volumes with these same folder's files that are currently on our 'web/public_html' folder. Make a zip of these folders and upload them to something like dropbox.  

```bash
# Access your production container with something like 'kubectl exec -it web-1752311019-2crsq -c web bash' for Kubernetes
# or even better: 'mp k ssh -c web' if you're using the MisPistachos CLI.

# Inside the production container download your data for the volumes:
wget https://www.dropbox.com/s/sfyy1234778xue/yourwebsitedata.zip
# Then unzip it and override the files
unzip -a yourwebsitedata.zip
# Answer 'A' to the override
# This only needs to be done once
chmod -R 777 modules/
chmod -R 777 themes/<yourtheme>/cache
chmod -R 777 themes/<yourtheme>/lang
# replace <yourtheme> with yours
```

## Troubleshooting:


### I need another version of Prestashop or PHP

To install another version of prestashop there is little to do. Download this official repo as a .zip and search for your desired version of Prestashop and PHP.
https://github.com/PrestaShop/docker

Copy the files inside the 'images/config_files' folder in the official repo and overwrite those in your 'web/config_files' folder.

Copy the beginning of the 'images/Dockerfile' file in the official repo and override the commands in your 'web/Dockerfile' file.

Now follow this tutorial from the beginning.


### Handle automatic redirects

Run 'docker-compose up web' to start the container.

If 'localhost:8080' redirects you to your old site, you can still access the admin interface in the URL 'localhost:8080/admin-yourwebsite' (or how you named it).

Here you can search 'domain' in the searchbar and change it locally to 'localhost:8080' instead of your old domain.

The same applies to your Kubernetes IP or a new domain.


### What to do if you don't know the password for the main user?

The simplest way to generate a new password (for example 'mypassword') is as follows :
1. Open /config/settings.inc.php and copy the COOKIE_KEY value, a string like:
ugVz7xCw9mYzkUWL1285CCyLb5dQOyNgnTxXDrGP0LZNBLrzKTvWyC0n
2. Open http://www.md5.fr or http://www.md5.cz and in the field, paste the copied string immediately followed (without space) by your password:
ugVz7xCw9mYzkUWL1285CCyLb5dQOyNgnTxXDrGP0LZNBLrzKTvWyC0nmypassword
Submit the form and copy the generated MD5 hash which looks like:
c838e4909b92e180e6428e85c15b003d
3. In your database, in the ps_employe table, locate the record that contains the e-mail address (of an admin) you want to use to connect to the database using:
$ mysql -p<password> prestashop
$ mysql> SELECT * FROM ps_employee;
4. Update the user's password using:
$ mysql> UPDATE ps_employee SET passwd='c838e4909b92e180e6428e85c15b003d' WHERE email = 'user@yourdomain.com';

### How do I backup my files without FTP access?

```bash
# On the web container, you can create the backup with these commands:
apt-get update
apt-get install zip -y
find /var/www/html -path '*/.*' -prune -o -type f -print | zip ~/old_site.zip -@

# AWS install on ubuntu OS
apt-get update \
&& apt-get install wget python -y \
&& apt-get install -y s3cmd \
&& wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | apt-key add - \
&& wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list \
&& apt-get update \
&& apt-get install -y --force-yes --no-install-recommends s3cmd=1.0.0-4 \
&& apt-get clean \
&& apt-get autoremove -y \
&& rm -rf /var/lib/apt/lists/*

# AWS install on Alpine OS
wget https://www.dropbox.com/s/47bbbm6c68dxdas/s3cmd-1.5.2.tgz
cp s3cmd-1.5.2.tgz /usr/local/bin/

# Configure aws
vim /root/.s3cfg #add your config file
cp .s3cfg /root/.s3cfg

# Upload the files from the old web container
s3cmd put ~/old_site.zip s3://db-dumps-mp/

# On the new web container, you also want to install and configure AWS
# Download the files on the new web container
export S3PATH="s3://db-dumps-mp/"
export FULLPATH="old_site.zip"
s3cmd get $S3PATH$FULLPATH
cd /
unzip -o $FULLPATH
```

### How do I setup WebPay (Chile) on this new server?

**NOTICE**: WebPay KCC will soon be deprecated.

```bash
# Navigate to the destination folder
wget https://www.dropbox.com/s/3yo38g50jabuhru/cgi-bin.zip
unzip -a cgi-bin.zip
rm cgi-bin.zip
# Don't forget to check the files you are puting in the base image and make sure that the IP in the tbk_config.dat file is the same one as the one in your server.
chmod -R 755 cgi-bin/
chmod 775 cgi-bin/*.cgi
chmod -R 777 cgi-bin/log/
# Now you have to commit these changes and upload them to the base image (or add them before pushing it to gcr.io)
# Finally, log in to the website and add the cgi-bin and log folders to the KCC module configuration, using absolute paths (/var/www/html/cgi-bin). This will be edited in the database and module folder (which are persistent)
```
