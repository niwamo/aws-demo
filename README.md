# AWS Demo

## About

This repository contains the source code and packer + terraform configurations
necessary to deploy a simple containerized web application with a Mongo backend
to AWS EKS.

There are intentional security flaws in the several aspects of the
infrastructure and application, such as:

-   Using a very out-of-date Ubuntu AMI as our starting point for the Mongo server
-   Allowing public access to port 22 on our Mongo server
-   Disable-able input sanitation in the web application
-   Hard-coded MongoDB credentials in the Packer and Terraform configurations

## Components

### 0_mongo-template

Creates an AMI with the MongoDB server installed.

It is designed to be a "stateless VM". All database files are stored on an
attached EBS, and the VM itself can be deleted/rebuilt with no loss of data.

When a VM is launched from the AMI, the
`pre-mongo` service installed by the packer configurations will:

-   look for an attached EBS
-   if an EBS is present, it will look for a filesystem
-   if a filesystem is present, it will mount it to /ebs
-   if MongoDB data is already present, the service will exit successfully
-   if MongoDB data is not already present, the service will create a new
    'aws-demo' database with credentials 'aws-demo:aws-demo' and exit successfully

If the `pre-mongo` service does not exit successfully, the mongo server will not
start.

### 1_app

The web application used by this repo has been split out into its own
repository, [pastebin](https://github.com/niwamo/pastebin). You can read more
about it there.

It is included here as a
[submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules).

It contains the source code, `docker-compose` configurations to test locally,
and `terraform` configurations to both build the container and push it to AWS
ECR.

### 2_deploy

Deploys the application to AWS.

## To Build / Deploy in Your Environment

1. Clone the repo
    - **Note**: `1_app` is a submodule, so you will need to include
      `--recurse-submodules` in your git command
2. Prep your environment
    - Required
        - `packer` (building VM template / AMI)
        - `docker` (building container image for web app)
        - `terraform` (deploying infra to AWS)
    - Recommended
        - `sops` + `age` (secrets management)
        - `docker-compose` (testing web app locally)
            - `docker-compose up -d`
            - `docker-compose down --rmi all -v --remove-orphans`
        - `aws` (troubleshooting)
            - Note: `aws` will be authenticated by the same environment variables
              described below for `tf` and `packer`
        - `kubectl` (troubleshooting)
            - Note: assuming you have used the suggested environment variables, you
              can authenticate `kubectl` with:
              `aws eks update-kubeconfig --region us-east-2 --name app`
3. Create the required stateful resources in AWS
    - These are **not** managed with `terraform`
    - Create an EBS (note the volume ID)
4. Generate an SSH keypair. Store the public key as `key.pub` in the root of
   this directory. This will be used for the MongoDB VM
5. (Optional) Configure sops and age
6. (Optional) Create your (encrypted) secrets
    - `env.sh.sops`
    - `key.sops`
    - _more on this below_
7. Export `env` variables (if using `sops`: `. <(sops -d env.sh.sops)`)
    - Required for AWS authentication:
        - `AWS_ACCESS_KEY_ID`
        - `AWS_SECRET_ACCESS_KEY`
        - `AWS_REGION`
    - Required for the application
        - `TF_VAR_DB_EBS_ID` (the volume ID of the EBS from step #3)
8. `cd` into `0_mongo-template`, `packer init` and `packer build .`
9. `cd` into `1_app`, `terraform init` and `terraform apply`
10. `cd` into `2_deploy`, `terraform init` and `terraform apply`
    - Variables (`2_deploy/1_vars.tf`):
        - `allowed_IPs_for_admin` sets the allowed IPs for the Mongo VM, as well as
          for the k8s control plane
        - `local.unsafe_app` determines whether the application will be vulnerable
          to stored XSS ("1" == vulnerable)

Note: You'll want to shutdown the Mongo VM before `terraform destroy`ing your
infra. AWS doesn't like to remove EBS volume attachments while the VM has the
EBS mounted. This could potentially be automated with a destroy-time remote-exec
provisioner in the terraform config, but that would create new requirements
around authentication material.

## Secrets Management

I recommend using sops + age for encrypting secrets, which can then be included in
the source code. This is not recommended for large, multi-user projects, but
works just fine for small, single-user pilots.

For information on setting up sops and age, see:

-   [my article](https://nicholas-morris.com/articles/sops) (which I've been
    meaning to update)
-   https://github.com/getsops/sops/discussions/1132
-   https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
-   https://technotim.live/posts/rotate-sops-encryption-keys/
-   https://sleeplessbeastie.eu/2024/03/20/how-to-utilize-sops-with-age-encryption/

Once the basic config is complete:

1. Generate a new age key
2. Add the key to `~/.config/sops/age/keys.txt`
3. Add a new rule to `~/.sops.yaml` to use that key for this repo
4. Overwrite `env.sh.sops`

```sh:env.sh.sops
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION=""
export TF_VAR_DB_EBS_ID=""
```

5. Generate a new ssh keypair
6. If you wish to keep the private key in the repo, do so with a sops-encrypted
   file

Note: the Terraform configuration currently does not require the private SSH
key - but if it did, it could use a sops-encrypted file using the 
[sops provider](https://registry.terraform.io/providers/carlpett/sops/latest/docs).
