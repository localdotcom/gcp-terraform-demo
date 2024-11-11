
# GCP Infrastructure


## Description
Provides IaC to deploy infrastructure to the Google Cloud using Terraform


## Prerequisites

- ### Create a Google Cloud project:
```bash
  gcloud projects create testwork-9682
```
- ### Select the Google Cloud project that you created:
```bash
  gcloud config set project testwork-9682
```
- ### Enable the Cloud Storage API:
```bash
  gcloud services enable storage.googleapis.com
```
- ### Create a Terraform backend bucket in the Google Cloud:
```bash
gcloud storage buckets create gs://testwork-9682-tfstate --location=EU
```
- ### Clone a git repo:
```bash
git clone https://github.com/localdotcom/testwork-9682.git
```


## Infrastructure

![ ](diagram.png)


## Deployment
```bash
cd ./testwork-9682/
./terraform plan gcs --project testwork-9682 --region europe-west1
./terraform apply gcs --project testwork-9682 --region europe-west1
./terraform plan iam --project testwork-9682 --region europe-west1
./terraform apply iam --project testwork-9682 --region europe-west1
./terraform plan lb --project testwork-9682 --region europe-west1
./terraform apply lb --project testwork-9682 --region europe-west1
````

