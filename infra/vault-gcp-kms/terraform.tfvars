#-------------------------------------------------------------------------------------------
# Required:
#    * gcloud-project - set it to your GCP project name to provision cloud resources
#    * account_file_path - the full path to your Cloud IAM service account file location
#-------------------------------------------------------------------------------------------
gcloud-project = "omdv-homelab"
account_file_path = "../../../.bootstrap-secrets/credentials.json"
gcloud-region = "us-east1"
gcloud-zone = "us-east1-b"
key_ring = "vault-keyring"
crypto_key = "vault-key"
keyring_location = "global"
