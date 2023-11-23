# platform training

This project follows the Platform capability's Proficiency Project - Engineer. I have chosen AWS as the cloud provider due to its popularity and already having some familiarity.


## Step 1
### All infrastructure is deployed by code that is stored in a repo you deploy in your cloud environment

Options considered:
* Terraform
* AWS CloudFormation

#### Terraform
Terraform is an open source cloud agnostic infrastructure management tool and includes support for many third party modules via "providers". Infrasture is defined using HashiCorp Configuration Language. 

#### AWS CloudFormation
AWS CloudFormation is an AWS native infrastructure management tool, capable of auto-scaling and healing. It offers extensive support for many AWS services. Infrastructure is defined using YAML or JSON.

#### Comparison
Terraform allows for dynamic resource creation and provides a range of builtin functions. AWS CloudFormation is much more limited in comparison.

Terraform does require managing state, which isn't a concern with AWS CloudFormation. 

Being native to AWS, AWS CloudFormation is able to offer features beyond what terraform is capable of and is well synchronized with AWS services.

### Choice
I've chosen terraform as my IaC tool due to it's versatility and range of providers which make it useful across cloud providers and capabilities beyond that.

## Step 2
### All code is authored in IDE of your choice
I'm using VSCode as my editor because it's free and flexible due to the range of available extensions.

## Step 3
### Deploy nginx in a HA configuration with an auto-scaling policy.  Everything must be automated via code.
#### What is nginx?
Nginx is an HTTP and reverse proxy server, a mail proxy server, and a generic TCP/UDP proxy server.

#### TODO What is it's role in this project?

#### What is high availability?
High availability is a strategy for managing small but critical failures in components, both planned and unplanned outages, and allows services to remain available.

High availability consits of:
* redundancy
* replication 
* failover
* fault tolerance

See https://www.cisco.com/c/en/us/solutions/hybrid-work/what-is-high-availability.html#~infrastructure-elements for more details on how each of these is achieved.

#### What is high availability on AWS?
https://docs.aws.amazon.com/whitepapers/latest/real-time-communication-on-aws/high-availability-and-scalability-on-aws.html

To ensure high availability, systems should be designed with no single point of failure. These are commonly eliminated through `N+1` or `2N` redundancy configuration, coresponding to configuring active-active nodes and active-standby node pairs respectively.
Route 53 checks resource health and can be configured with either failover strategy.

Systems should also correctly monitor availability and have prepared procedures for manual failure recovery mechanisms.

##### N+1 Active-Active Nodes
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover-types.html

Active-active failover configuration allows all resources to be available the majority of the time. Upon detecting an unhealthy resource, that resource is excluded when responding to queries.

##### 2N Active-Standby Nodes
https://docs.aws.amazon.com/whitepapers/latest/real-time-communication-on-aws/floating-ip-pattern-for-ha-between-activestandby-stateful-servers.html

It is not always possible to have multiple active instances of the same component running, as in the active-active configuration. For example, stateful components in real time communication solutions such as media servers. 

Automatic failover of such systems can be achieved through the floating IP design pattern. This involves a static virtual IP address assigned to the active node and will be swapped to the standby node on detection of failure.


#### AWS Best practices
https://docs.aws.amazon.com/whitepapers/latest/real-time-communication-on-aws/best-practices-from-the-field.html

Best practices from large real-time Session Initiation Protocol (SIP) workloads:
* Perform detailed monitoring
* Use DNS load balancing and floating IP failover
* Use multiple Availability Zones
* Keep traffic within one Availability Zone and use EC2 placement groups
* Use enhanced networking EC2 instance types

While being specific to SIP workloads, the concepts are transferable across AWS. Some AWS services handle aspects automatically. See AWS whitepapers for more specific use cases https://aws.amazon.com/whitepapers

#### Choosing an AWS service to host the nginx container
This video https://pages.awscloud.com/Building-Modern-Applications-at-AWS_2019_0813-SRV_OD.html?b4e47a47-3ea8-45bc-9260-b4087b5e6679 recommends choosing the most managed service that allows the necessary control. Since nginx will be deployed as a docker container, Amazon Elastic Container Service (ECS) is most appropriate.

#### Deployment steps

0. Setup CICD
1. Create an nginx docker image
2. Upload the image to AWS ECR
3. Run the image in AWS ECS

## Interlude to setup the CICD

Terraform state file keeps track of the current infrastructure. It's terraforms source of truth. Anyone working on the same terraform infrastructure needs access to that state file. However you could easily run into conflict with multiple people making changes and on top of that terraform state file holds passwords in plain text, so isn't suitable for git. Instead use terraform remote state with the file stored in an S3 bucket. This also makes it easy for the pipeline to manage.

To run in the pipeline, we need a way to configure aws access securely.
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html

For that we'll setup OIDC. This involves:
1. Configure an OpenID connect identity provider in the IAM console using the provider URL and audience here: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#adding-the-identity-provider-to-aws
2. Create a role with the newly created identity provider and the required permissions
3. Update the trust policy with the specific git repo and branch
4. github workflow (beware https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#filtering-for-a-specific-branch)

## Upload the image to ECR

An ECR repository can be created easily using the `aws_ecr_repository` resource in terraform, requiring only a name.

Most projects will require unique image tags for each build for reproducibility. To facilitate this, set `image_tag_immutability` to `IMMUTABLE`. To create unique tags, I chose the git hash as this easily identifies the associated commit and can easily be retrieved in the cicd pipeline using the `github.sha` variable.

Then enable image scanning on push with
```
image_scanning_configuration {
    scan_on_push = true
  }
```

To push to this repository in the pipeline, login to ECR using `aws-actions/amazon-ecr-login@v1` action. Then run the usual docker commands to build and push the image, making sure to tag it appropriately `$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG`.

## Run the image in ECS

To set up the image in ECS using AWS Fargate:
1. Create an `aws_ecs_cluster`
2. Create an `aws_ecs_task_definition` defined by the nginx image
3. Define data for the `aws_subnet_ids`
4. Create an `aws_ecs_service` within the cluster, defined by the task definition, and configure the network to use the subnet.

Possibly using https://docs.aws.amazon.com/AmazonECS/latest/userguide/ECS_AWSCLI_Fargate.html
But converting to terraform

### High availability
Tasks use the replica scheduling strategy by default, which balances tasks across availability zones.
Ref: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html#service_scheduler_replica

### Autoscaling
ECS autoscaling is managed by Application Auto Scaling, which requires aws_appautoscaling_target and aws_appautoscaling_policy to be configured in terraform.
Ref: https://docs.aws.amazon.com/autoscaling/application/userguide/what-is-application-auto-scaling.html

### Receiving inbound connections
To access ping our docker container from the internet, it needs to accept inbound connections. For large scale HTTP based services, either Application Load Balancer or Amazon API Gateway are well suited to provide a scalable input layer. ALB costs per hour, whereas API Gateway charges per request. However API Gateway distributes traffic based on endpoints, so still requires a load balancer to 

For local use you can add inbound rules, to the security group, to allow anyone to access the web server port and to allow pinging.

Ref: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/networking-inbound.html

### Connecting to the container
Use aws ecs execute-command on the cli:
`aws ecs execute-command --cluster platform-training-cluster --task <task-id> --container platform-training-app --interactive --command "sh"`
Windows shenanigans seem to only work without the "/bin/" prefix and bash isn't in the path of the nginx image.

This required enabling execute command in the ecs service, and providing additional permissions through the task_role_arn of the task definition. As well as downloading session-manager-plugin for the cli.

Ref: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html

### Troubleshooting

#### Configure AWS credentials 
> Error: Not authorized to perform sts:AssumeRoleWithWebIdentity

This was due to specifying a branch in the role, but using environment in the github action which prevents sending the branch to OIDC.

#### Terraform init
> Error refreshing state: AccessDenied: Access Denied

Role was setup with Get/Put/Delete Object with the bucket as the resource, but it needed a wildcard to allow recursive permissions.

#### Terraform apply
> Error: configuring Terraform AWS Provider: IAM Role (arn:aws:iam::***:role/platform-cicd-oidc) cannot be assumed.

Using IAM role configured in the previous step of github actions works, doesn't need to be set in the terraform configuration too.

#### ECS
> Error: no container instances found in cluster

Terraform successfully applied and the pipeline passed, but when checking AWS console the task failed to start. This was due to specifying aws_ecs_service without a launch_type, which defaults to EC2 instead of FARGATE.

> Error: ECS was unable to assume the role 'AWSServiceRoleForECS' that was provided for this task