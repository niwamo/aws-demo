# AWS Demo

## Steps

### GitHub Repo

### AWS Account Setup

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

```sh
age-keygen
```

Add to `~/.config/sops/age/keys.txt`

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

Before running packer or terraform, run `. <(sops -d ./secrets.sh.enc)`

### Getting the Stateless VM

#### Packer

1. MVP ()

#### CI/CD for Packer

#### Terraform

#### CI/CD for Terraform

### Web App 

#### Build the app

#### Build the container

#### CI/CD for container + ECR

### App CI/CD

### Stateful Resources

#### EBS for DB

#### S3 Bucket

### Automated Backups
