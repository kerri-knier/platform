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

To ensure high availability, systems should be designed with no single point of failure. These are commonly eliminated through `N+1` or `2N` redundancy configuration, coresponding to configuring active-active nodes and active-standy node pairs respectively.
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

1. Create an nginx docker image
2. Upload the image to AWS ECR
3. Run the image in AWS ECS