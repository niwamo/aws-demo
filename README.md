# AWS Demo

## To Build / Deploy in Your Environment

1. Prep your environment
   - Required
     - `sops` + `age` (secrets management)
     - `packer` (building VM template / AMI)
     - `terraform` (deploying infra to AWS)
     - `docker` (building container image for web app)
   - Recommended
     - `docker-compose` (testing web app image locally)
       - `docker-compose up -d`
       - `docker-compose down --rmi all -v --remove-orphans`
     - `aws` (troubleshooting)
       - Note: `aws` will be authenticated by the same environment variables
         described below for `tf` and `packer`
     - `kubectl` (troubleshooting)
       - Note: assuming you have used the suggested environment variables, you
         can authenticate `kubectl` with: 
         `aws eks update-kubeconfig --region us-east-2 --name app` 
2. Create the required stateful resources in AWS
   - These are **not** managed with `terraform`
   - Create an EBS (note the volume ID)
   - Create an S3 bucket
     - **TODO - not complete**
3. Configure sops and age
4. Replace my (encrypted) secrets with your own (encrypted) secrets
   - `env.sh.sops`
   - `key.pub` (okay, this one's not actually encrypted)
   - `key.sops`
   - *more on this below*
5. Export `env` variables for auth (`. <(sops -d env.sh.sops)`)
6. `cd` into `0_mongo-template`, `packer init` and `packer build .`
7. `cd` into `1_app\tf`, `terraform init` and `terraform apply`
   - **Note**: change `local.unsafe_app` in `1_vars.tf` to "1", if you want the
     application to be vulnerable to stored XSS
8. `cd` into `2_deploy` and `terraform apply`
9. Profit

## Secrets Management

This project uses sops + age for encrypting secrets, which are then included in
the source code. This is not recommended for large, multi-user projects, but
works just fine for small, single-user pilots.

For information on setting up sops and age, see:

- [my article](https://nicholas-morris.com/articles/sops) (which I've been
  meaning to update)
- https://github.com/getsops/sops/discussions/1132
- https://devops.datenkollektiv.de/using-sops-with-age-and-git-like-a-pro.html
- https://technotim.live/posts/rotate-sops-encryption-keys/
- https://sleeplessbeastie.eu/2024/03/20/how-to-utilize-sops-with-age-encryption/

Once the basic config is complete:

1. Generate a new age key
2. Add the key to `~/.config/sops/age/keys.txt`
3. Add a new rule to `~/.sops.yaml` to use that key for this repo
4. Overwrite `env.sh.sops`

```sh:env.sh.sops
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION=""
export TF_VAR_AWS_REGION=${AWS_REGION}
export TF_VAR_DB_EBS_ID=""
```

5. Generate a new ssh keypair
6. If you wish to keep the private key in the repo, do so with a sops-encrypted
   file 