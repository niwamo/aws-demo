# AWS Demo

## Steps

### Create GitHub Repo

### Create AWS Account

1. Create account
2. Setup MFA on root account
3. [Create an account alias](https://docs.aws.amazon.com/IAM/latest/UserGuide/account-alias-create.html)
4. [Set default region](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/change-default-region.html)
5. Set up an [AWS Organization](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_tutorials_basic.html)
6. [Set up SSO](https://docs.aws.amazon.com/singlesignon/latest/userguide/idp-microsoft-entra.html)
   - Note: in Step 2.1, use the predefined permission set 'AdministratorAccess'
7. Enable Service Control Policies and block the creation of additional Identity
   Center instances
8. [Enable billing console access for IAM Users](https://stackoverflow.com/questions/74728379/)
9. Set up billing alerts

### Setup Auth and Secrets

#### New Age Key + Age Config

[ref](https://nicholas-morris.com/articles/sops)

```sh
# generate a new key
age-keygen
```

Add key to `~/.config/sops/age/keys.txt`

Add new rule to `~/.sops.yaml`

```yaml
creation_rules:
 - path_regex: '<dirname>'
 - age: '<public key>'
```

#### IAM Setup

1. Create policy with least privileges
2. Create user and assign policy
3. Create access key
4. Add access key to sops-encrypted file

```sh:secrets.sh.enc
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION=""
```

Before running packer or terraform, run `. <(sops -d ./env.sh.sops)`

### Stateless MongoDB VM

Isolate the minimum possible amount of stateful-ness. 
Keep the VM and DB server stateless. Only the database files themselves will
be maintained via an EBS.

#### Create EBS

Note: add volume ID to `env.sh.sops` as `TF_VAR_DB_EBS_ID`

#### Packer

1. Confirm Packer function/auth 
   - `git show bf78f5d19b:packer/mongovm/main.pkr.hcl`
2. Manually deploy, connect, work through Mongo installation process
   - `mongod.conf` to listen on all IPs and require auth
   - systemd unit file to:
      1. Check for ELB block device; fail if not present
      2. If present, check for filesystem and DB
      3. If no filesystem, format and instantiate DB
   - ensure `mongod` fails if `pre-mongo` is not successful
3. Create functioning, stateless VM template (AMI)
   - `git show 635781d497:packer/mongovm/main.pkr.hcl`

#### Terraform

1. Confirm Terraform function/auth
2. Deploy basic network + a VM from AMI
   - `git show 6b47a6e885:terraform/`

### Web App 

#### Proof of Concept

1. Use a basic dockerfile + nginx install for an "MVP" web app
2. Build locally and push to AWS using terraform
3. Build terraform config for EKS with a publicly exposed deployment
   - `git show 1dd7a1021b:`

#### Actual App

1. Build a PoC golang web app
2. Use docker-compose to deploy the web app and a stand-in for the Mongo VM 
3. Build the PoC for connecting web server to golang
4. Parameterize the DB connection; provide DB string as environment variable
5. Test the DB connection and ENV approach against the AWS/EKS infra
6. Complete the app and deploy
   - `git show 77ab9dcd6e:`

### Wrapping Up Requirements

#### Backups

#### CI/CD Pipelines
