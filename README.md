# prodyna-aws-training
Repository for the PRODYNA AWS and Terraform training.
## HowTo
### How To Staging
* Create environment directory in every component
* Create a sub-directory for every environment, e.g.
```
env
    dev
    stage
    test
    prod
```
* Extract remote backend configuration to a backend configuration file (e.g. backend.config), e.g.:
```
key = "live/poc/service/eks/terraform.tfstate"
shared_credentials_file = "../../../shared-credentials/aws-credentials"
profile = "fcs-shared-services"
```
* Extract (stage) variable assignments to variables file (e.g. terraform.tfvars), e.g.:
```
stage = "prod"
terraform_build_role_arn = "arn:aws:iam::XXXXXXX:role/myRole"
```
* Now we can reference the correct stage in our remote backend on init, e.g.:
```
terraform init -backend-config="./env/prod/backend.config”
```
* And propagate the correct stage variables on apply, e.g.:
```
terraform apply -var-file="./env/prod/variables.tfvars"
```

#### Example Structure
```
env
    dev
        backend.config
        terraform.tfvars
    stage
        backend.config
        terraform.tfvars
    test
        backend.config
        terraform.tfvars
    prod
        backend.config
        terraform.tfvars
main.tf
output.tf
variables.tf
```

### How To Add Features
The problem with Git branches are that you have got a different branch, but the same remote backend file.
The solution for this are Terraform workspaces. If you don't do anything you work on the "default"
workspace. You can see the current workspace with ```terraform workspace show ```.
To create a new workspace for a feature or bugfix use ```terraform workspace new workspaceName``` and 
```terraform workspace select workspaceName``` to select the new workspace. Every workspace got his
own (initial empty) terraform file. Non default workspaces save the Terraform file in ":env/xxx"
on the remote backend. That means this files can be created and edited from anyone.
To avoid naming conflict add the workspace name to your resource names, e.g.:
```name = "${local.stageName}-${local.projectName}-${terraform.workspace}-s3-frontend"```

The correct workflow for integrating changes to your infrastructure is:
1. Create branch
1. Create workspace
1. Add changes
1. Test changes (create new resources > test > destroy resources)
1. Select default workspace
1. Create Terraform plan and save output:
    1. ```terraform plan –out=myFeature.tfplan```
    1. Save terminal output to file (myFeature.tfplan.txt)
1. Create PR and add *.tfplan and *.tfplan.txt 
1. Merge

