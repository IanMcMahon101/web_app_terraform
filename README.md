# web_app_terraform

**NOTE:** *normally I would use variable validation, but this is also not yet available in TF 12*

## VPC Module


Input|Type|Description|
-----|----|-----------|
create_vpc | bool | A count variable on the module resources to enable or diable the module, this is a hacky way to get it done because TF 12 doesn't support module count yet|
vpc_name | string | string for the name tag of your VPC|
tags | map of strings | map of strings to put on all resources in your vpc|
cidr_block | string | string for the CIDR block you want to allocate to your VPC
dns_support | bool | Bool flag that enables or disables dns support on your vpc|  
dns_hostnames | bool | bool flag that enables or disables dns hostnames on your vpc| 
instance_tenancy | string | tenancy options for ec2's launched within VPC, default is "default" other valid options are "dedicated or "host"|
enable_classiclink | bool | bool flag to enable classiclink inside vpc|
enable_classiclink_dns | bool | bool to enable classiclink dns inside vpc |  
subnets | map of objects | map of objects to create subnets, appropriate attributes are: <ui><li>**subnet_name (string)** *subnet name*</li><li>**public (bool)***bool flag to enable or disable public subnets*</li><li>**newbits(number)***is the number of additional bits with which to extend the prefix*</li><li>**netnum(number)***is a whole number that can be represented as a binary integer with no more than newbits binary digits, which will be used to populate the additional bits added to the prefix*</li></ui> | 

## EC2 Module

Input|Type|Description|
-----|----|-----------|
public_subnet_id | string | can be used by calling vpc module output, this is the public subnet ID to place your LB in |
private_subnet_id | string | can be used by calling vpc module output, this is the private subnet ID to place your asg in |
vpc_id | string | can be used by calling vpc module output, vpc ID for various resource arguments | 
os | string | which OS you will be configuring your asg with, appropriate values are: "ubuntu" & "rhel" | 
lc_name | string | name of your launch configuration | 
instance_type | string | instance type for your auto scaling groups | 
instance_profile | string | instance profile to put on EC2's, assuming one is created |
ssh_user | string | name of user to be allowed ssh access |
pub_key | string | public ssh key for user to allow ssh access |
sudo | bool | bool flag that gives ssh user sudo access if set to true | 
ssh_cidr_blocks | list of strings | list of cidr blocks to allow ssh access to ec2's | 
egress_cidr_blocks | list of strings | cidr blocks to allow ec2's to communicate with |
root_volume_size | number | size of root volume on ec2's |
ebs_volume_size | number | size of additional ebs volumes |
asg_max | number | max number of nodes to scale to in the autoscaling groups | 
asg_min | number | min number of nodes to scale to |
asg_desired | number | desired amount of nodes to have when not in need of scaling |
eip_ip | string | can be called from vpc module output, this is the eip that will be asociated with the load balancer |
as_pol | map of objects | object to use that will create autoscaling policy, appropriate attributes are: <ui><li>**name(string)** *name of autoscaling policy*</li><li>**scaling_adjustment(number)** *number of instances in which to scale*</li><li> **adj_type(string)** *this is the adjustment type*</li><li>**cooldown(number)** *amount of time in seconds after scaling activity before next scaling activity can start</li></ui> |
alb | map of objects | object to create alb, appropriate values are: <ul><li>**name(string)** *name of alb*</li><li>**protect(bool)** *this enables or disables temrination protection via api or cli*</li></ui> |
high_mem_alarm | map of objects | this map of objects can be used to create as many cloudwatch alarms are necesary, appropriate values are: <ul><li>**name(string)** *name of alarm*;</li><li>**comp_op(string)** *The arithmetic operation to use when comparing the specified Statistic and Threshold*;</li><li>**eval_per(string)** *The number of periods over which data is compared to the specified threshold*;</li><li>**metric_name(string)** *The name for the alarm's associated metric*</li><li>**namespace(string)** *the namespace for the alarm's associated metric*</li><li>**period(number)** *The period in seconds over which the specified statistic is applied.*</li><li>**statistic(string)** *The statistic to apply to the alarm's associated metric. Either of the following is supported: SampleCount, Average, Sum, Minimum, Maximum*</li><li>**threshold(string)** *the value against which the specified statistic is compared.*</li><li>**description(string)** *the decription of your alarm*</li></ul>  