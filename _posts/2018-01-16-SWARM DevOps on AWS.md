---
layout: post
title: DevOps on AWS Application Pipeline and WebApp Pipeline
description: How we setup AWS Application pipeline and WebApp pipeline in SWARMNYC.
tags: 
    - DevOps
    - Continuous Integration
    - AWS Application Pipeline
    - AWS WebApp Pipeline
---

<!-- Cumstomzie image style: having border, horizontal center, white background -->
<style>
    img {
        border: solid 1px lightgrey;
        background-color: white;
        display: block;
        margin-left: auto;
        margin-right: auto;
    }
</style>

In <a href="https://www.swarmnyc.com" target="_blank">SWARM</a>, we use these comprehensive step-by-step guides to build a production-ready devops solution.

* [Setup Application Pipeline](#application-pipeline-setup-overview)

* [Setup WebApp Pipeline](#webapp-pipeline-setup)

# Application Pipeline Setup (Overview)

![image alt text](image_0.png)

1. [ECR Repositories](#ecr-repositories-setup)

	Create ECS Repositories first, where the Dev team could build and push the application’s Docker image.

2. [Target Groups](#target-groups-setup)
	
	Target Groups are referenced by Load Balancer. Let’s create them before doing Load Balancer.

3. [Load Balancer](#load-balancer-setup)
	
	After a Load Balancer is created, you will get a DNS name(A Record) of it. Point all your site domain name to this DNS name.
	![image alt text](image_1.png)

4. [ECS Cluster](#ecs-cluster-setup)
	ECS Cluster is a container, where we can create Task Definitions and Services. An EC2 instance will also be created automatically while creating the ECS Cluster.

5. [ECS Task Definitions](#ecs-task-definitions-setup)

	Specify which Docker image should be used, how much CPU and memory to use, whether should the console logging message redirect to CloudWatch.

6. [ECS Services](#ecs-services-setup)

	Specify how many tasks should be run, which Task Definition should be use, which Target Group as well as Load Balancer should be register to.

7. [EC2 instance](#ec2-instance-setup)

	EC2 instance are created within ECS Cluster. We need to add an Inbound rule letting the Load Balancer redirect requests to.

# Pipeline Components Setup (Detail Operations)

## Target Groups setup

1. AWS console ⇒ EC2:

	![image alt text](image_2.png)

2. Target Groups ⇒ Create target group

	![image alt text](image_3.png)

3. Create 2 groups

	* Ludlow2-api-qa
	* Ludlow2-api-prod

	The port doesn’t matter, keep it as default: 80.

	VPC: pick one, make sure it is the same as the one in your Load Balancer and EC2 Instance.

	![image alt text](image_4.png)

4. After the target group created, double check tab "Health checks", and make sure your server will return a code within “Success codes” on the path “/”.

	![image alt text](image_5.png)

## Load Balancer setup

1. AWS console ⇒ EC2 ⇒ Load Balancers ⇒ Create Load Balancer

	![image alt text](image_6.png) 

2. Select: Application Load Balancer

	![image alt text](image_7.png)

3. Add 2 Listeners: HTTP / HTTPS, Select All Availability Zones.

	![image alt text](image_8.png)

4. Choose a certificate

	![image alt text](image_9.png)

5. Select an existing security group: default

	![image alt text](image_10.png)

6. New target group or Select existing one: Ludlow2-api-prod. Port doesn’t matter, keep it as default: 80.

	![image alt text](image_11.png)

7. No need to Register Targets, which will be register automatically by our ECS Services.

	![image alt text](image_12.png)

8. Review and Create

	![image alt text](image_13.png)

9. Select the new created Load Balancer: Ludlow2 ⇒ Listeners: 80/443 ⇒ View/edit rules

	![image alt text](image_14.png)

10. Add a rule: If Host is qa.ludlow.io forward to Target Group: Ludlow2-api-qa

	![image alt text](image_15.png)

## EC2 Instance setup

The EC2 instance where we need to add an inbound rule letting a Load Balancer redirect the request, should be created while creating ECS Cluster below.

1. AWS console ⇒ EC2 ⇒ Instances ⇒ Ludlow2 ⇒ click Security groups

	![image alt text](image_16.png)

2. Inbound ⇒ Edit

	![image alt text](image_17.png)

3. Add Rule, Type pick All TCP, Source input the Security Group ID(sg-964aa2ef) from Load Balancer: Ludlow2

	![image alt text](image_18.png)   ![image alt text](image_19.png)

## ECS Cluster setup

1. AWS console ⇒ Elastic Container Service:

	![image alt text](image_20.png)

2. Clusters ⇒ Create Cluster

	![image alt text](image_21.png)

3. Select EC2 Linux + Networking

	![image alt text](image_22.png)

4. Use default EC2 instance.

	![image alt text](image_23.png)

5. Networking use existing VPC, Subnet, and Security group. Security group should be the same as the one in Load Balancer, i.e. default.

	![image alt text](image_24.png)

## ECR Repositories setup

1. AWS console ⇒ Elastic Container Service ⇒ Repositories ⇒ Create repository

	![image alt text](image_25.png)

2. Create two repositories: ludlow2-api-qa, ludlow2-api-prod.

	![image alt text](image_26.png)

3. Write down the commands, which will be used in CI platform: TeamCity.

	![image alt text](image_27.png)

## ECS Task Definitions setup

1. AWS console ⇒ Elastic Container Service ⇒ Task Definitions ⇒ Create new Task Definition

	![image alt text](image_28.png)

2. Select EC2 as launch type compatibility

	![image alt text](image_29.png)

3. Configure task and container definitions

	![image alt text](image_30.png)

4. Add container

	![image alt text](image_31.png)

5. Standard configuration:

	* Image points to the Repository we just created: ludlow2-api-qa

	* Memory Limits should set to Hard limit for qa, just in case of affecting the prod Task’s memory

	* Port mappings: Host port must be set to 0, in order to register to a Target Group with a dynamic port, which allow two different Tasks([Blue/Green Deployment](https://docs.cloudfoundry.org/devguide/deploy-apps/blue-green.html)) running at the same time, one for old version image, one for new version image. Container port is whatever you set in application’s Dockerfile.

	![image alt text](image_32.png)

6. Advanced container configuration

	* STORAGE AND LOGGING ⇒ Log configuration ⇒ check Auto-configure CloudWatch Logs, this makes sure all the console log will go to CloudWatch.

	![image alt text](image_33.png)

## ECS Services setup

1. AWS console ⇒ Elastic Container Service ⇒ Clusters ⇒ Ludlow2

	![image alt text](image_34.png)

2.  Services ⇒ Create

	![image alt text](image_35.png)

3. Configure services

	![image alt text](image_36.png)

	* Make sure Maximum percent * Number of tasks >= Number of tasks + 1, letting your new task can be started while the old one is stopping.

4. Configure network

	* Load balancer type: Application Load Balancer

	![image alt text](image_37.png)

	* Select Load Balancer: Ludlow2, Click Add to load balancer

	![image alt text](image_38.png)

	* Target group name, pick Ludlow2-api-qa

	![image alt text](image_39.png)

# WebApp Pipeline Setup

![image alt text](image_40.png)

## S3 Bucket setup

1. AWS console ⇒ S3:

	![image alt text](image_41.png)

2. Create bucket

	![image alt text](image_42.png)

3. Name and region: put a name, e.g. ludlow-frontend

	![image alt text](image_43.png)

4. Take the default settings and Create bucket

	![image alt text](image_44.png)

## CloudFront setup

1. AWS console ⇒ CloudFront:

	![image alt text](image_45.png)

2. Create Distribution

	![image alt text](image_46.png)

3. Pick Web as the delivery method

	![image alt text](image_47.png)

4. Origin Settings: 

	* pick the S3 Bucket just created. E.g. ludlow-frontend.s3.amazonaws.com

	![image alt text](image_48.png)

5. Default Cache Behavior Settings:

	* Viewer Protocol Policy: Redirect HTTP to HTTPS

	![image alt text](image_49.png)

6. Distribution Settings

	* Alternate Domain Names(CNAMEs): your app’s url. E.g. app.ludlow.io

	* SSL Certificate: check Custom SSL Certificate, and pick the certificate to your app.

	* Others: keep them as are.

	![image alt text](image_50.png)

7. Click Create Distribution and you’re all set.

	![image alt text](image_51.png)

8. After the Distribution is created, you can have its Domain Name: d19daj4piv5qj9.cloudfront.net.

	![image alt text](image_52.png)

9.  You must create a CNAME record with your DNS service to route queries for api.ludlow.io to d19daj4piv5qj9.cloudfront.net

	![image alt text](image_53.png)



