---
layout: post
title: AWS deployment OPs
description: AWS deployment routine operations.
tags: 
    - AWS
    - deployment
---

<style type="text/css">
    img {
        display: block;
        border: 1px solid black;
    }
</style>

# Application Pipeline in AWS

![image alt text](image_0.png)

## Target Groups setup

1. AWS console ⇒ EC2:
![image alt text](image_1.png)
2. Target Groups ⇒ Create target group
![image alt text](image_2.png)
3. Create 2 groups
    * Ludlow2-api-qa
    * Ludlow2-api-prod

The port doesn’t matter, keep it as default: 80.
![image alt text](image_3.png)

## Load Balancer setup

1. AWS console ⇒ EC2 ⇒ Load Balancers ⇒ Create Load Balancer
![image alt text](image_4.png) 
2. Select: Application Load Balancer
![image alt text](image_5.png)
3. Add 2 Listeners: HTTP / HTTPS, Select All Availability Zones.
![image alt text](image_6.png)
4. Choose a certificate
![image alt text](image_7.png)
5. Select an existing security group: default
![image alt text](image_8.png)
6. New target group or Select existing one: Ludlow2-api-prod. Port doesn’t matter, keep it as default: 80.
![image alt text](image_9.png)
7. No need to Register Targets, which will be register automatically by our ECS Services.
![image alt text](image_10.png)
8. Review and Create
![image alt text](image_11.png)
9. Select the new created Load Balancer: Ludlow2 ⇒ Listeners: 80/443 ⇒ View/edit rules
![image alt text](image_12.png)
10. Add a rule: If Host is qa.ludlow.io forward to Target Group: Ludlow2-api-qa
![image alt text](image_13.png)

## EC2 Instance setup

The EC2 instance where we need to add an inbound rule letting a Load Balancer redirect the request, should be created while creating ECS Cluster below.

1. AWS console ⇒ EC2 ⇒ Instances ⇒ Ludlow2 ⇒ click Security groups
![image alt text](image_14.png)
2. Inbound ⇒ Edit
![image alt text](image_15.png)
3. Add Rule, Type pick All TCP, Source input the Security Group ID(sg-964aa2ef) from Load Balancer: Ludlow2
![image alt text](image_16.png)   ![image alt text](image_17.png)

## ECS Cluster setup

1. AWS console ⇒ Elastic Container Service:
![image alt text](image_18.png)
2. Clusters ⇒ Create Cluster
![image alt text](image_19.png)
3. Select EC2 Linux + Networking
![image alt text](image_20.png)
4. Use default EC2 instance.
![image alt text](image_21.png)
5. Networking use existing VPC, Subnet, and Security group. Security group should be the same as the one in Load Balancer, i.e. default.
![image alt text](image_22.png)

## ECR Repositories setup

1. AWS console ⇒ Elastic Container Service ⇒ Repositories ⇒ Create repository
![image alt text](image_23.png)
2. Create two repositories: ludlow2-api-qa, ludlow2-api-prod.
![image alt text](image_24.png)
3. Write down the commands, which will be used in CI platform: TeamCity.
![image alt text](image_25.png)

## ECS Task Definitions setup

1. AWS console ⇒ Elastic Container Service ⇒ Task Definitions ⇒ Create new Task Definition
![image alt text](image_26.png)
2. Select EC2 as launch type compatibility
![image alt text](image_27.png)
3. Configure task and container definitions
![image alt text](image_28.png)
4. Add container
![image alt text](image_29.png)
5. Standard configuration:
    * Image points to the Repository we just created: ludlow2-api-qa
    * Memory Limits should set to Hard limit for qa, just in case of affecting the prod Task’s memory
    * Port mappings: Host port must be set to 0, in order to register to a Target Group with a dynamic port, which allow two different Tasks([Blue/Green Deployment](https://docs.cloudfoundry.org/devguide/deploy-apps/blue-green.html)) running at the same time, one for old version image, one for new version image. Container port is whatever you set in application’s Dockerfile.
![image alt text](image_30.png)
6. Advanced container configuration
    * STORAGE AND LOGGING ⇒ Log configuration ⇒ check Auto-configure CloudWatch Logs, this makes sure all the console log will go to CloudWatch.
![image alt text](image_31.png)

## ECS Services setup


1. AWS console ⇒ Elastic Container Service ⇒ Clusters ⇒ Ludlow2
    ![image alt text](image_32.png)
2.  Services ⇒ Create
    ![image alt text](image_33.png)
3. Configure services
    ![image alt text](image_34.png)
    * Make sure Maximum percent * Number of tasks >= Number of tasks + 1, letting your new task can be started while the old one is stopping.
4. Configure network
    * Load balancer type: Application Load Balancer
    ![image alt text](image_35.png)
    * Select Load Balancer: Ludlow2, Click Add to load balancer
    ![image alt text](image_36.png)
    * Target group name, pick Ludlow2-api-qa
    ![image alt text](image_37.png)

