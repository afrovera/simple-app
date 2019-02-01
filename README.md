Introduction
==================================================

You have a simple Spring Boot app responding “hello” to requests. Making it scalable, secure, and available in
multiple AWS regions is part of the job. You have the whole AWS stack to automate it; put this app in the
cloud, launch it and secure it. During the process, you are expected to identify risks and come up with
recommendations to improve the security posture of the app and infrastructure.

For this assignment, deployment in multiple availability zones is sufficient but you can also try spreading the
app in multiple regions.

Assignment
-----------

The sources you will deploy can be found at https://github.com/lc-nyovchev/opstest/tree/master. Launching
the app is possible with the following command:
./mvnw spring-boot:run -Dspring.config.location=/tmp/application.properties
We expect a complete solution that will:
1. Start the app in at least 3 availability zones. You are free to select the most secure solution to
accomplish this.
2. Each app instance should be provisioned in such a way that hitting the /hello URL displays the
availability zone on which the app is located.
3. Load balance the requests across all availability zones. Forty-two hits to the load balancer will give at
least one response from each availability zone.
4. Terminating an instance within the AZ should trigger the creation of another instance in the same AZ,
but the availability of the service shouldn’t be interrupted.
5. Implement security best practices for app and infrastructure.


Consider
---------------

- Protecting sensitive credentials
- Minimizing the impact if an attacker should break through the app

Deliver
------------------

1. A project hosted in an accessible location (GitHub is fine) with some instructions on how to run and a
small description of what it does.
2. A (short) list of risks identified in the source of commit
https://github.com/lc-nyovchev/opstest/tree/389aa8a2c7c410542e1517c92b8d714c76dd387b of
the app.
3. A recommendation to improve the security of the app or infrastructure in your project.

Steps to deploy
------------------

These steps assume that you have an AWS credentials with minimum required privileges and domain name to test the AWS-managed SSL configuration. The number of services deployed by this project requires very broad IAM permissions, I recommend using MFA-protected IAM role with such policy. 

1. Prepare AWS Account by creating EC2 Keypair to SSH to the instances and S3 bucket for storing CodeBuild Artifacts and Amazon-issued SSL certificate for securing the website. 

*Create EC2 keypair in 2 regions (default opstest).
aws ec2 create-key-pair --key-name opstest --region us-east-1
aws ec2 create-key-pair --key-name opstest --region eu-west-1

*Create an S3 bucket for storing CodeBuild Artifacts (default devsecops-opstest).
aws s3api create-bucket --bucket devsecops-opstest --region us-east-1
aws s3api create-bucket --bucket devsecops-opstest --region eu-west-1

*Amazon-issued SSL certificate for securing the website in 2 regions (replace www.example.com with actual domain name).
aws acm request-certificate --domain-name example.com --validation-method DNS --subject-alternative-names www.example.com --region us-east-1
aws acm request-certificate --domain-name example.com --validation-method DNS --subject-alternative-names www.example.com --region eu-west-1

*[Validate Certificate] (https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html#gs-acm-use-dns) by creating CNAME record for the domain and wait for certificate to be issued (approximately 5 minutes with Route 53).

*If you canont update DNS records for the domain, use e-mail validation.
aws acm request-certificate --domain-name example.com --validation-method EMAIL --subject-alternative-names www.example.com --region us-east-1
aws acm request-certificate --domain-name example.com --validation-method EMAIL --subject-alternative-names www.example.com --region eu-west-1

2. Create [VPC Stack](https://github.com/afrovera/quickstart-aws-vpc/blob/master/templates/aws-vpc.template) with Public/Private subnets in multiple availibility zones.
3. Create [Code Pipeline Stacks] (https://github.com/afrovera/devsecops/blob/master/templates/opstest-pipeline-github.template) in 2 regions with Git source of this repo.
4. Create Infrastructure with AWS High Availibility Beanstalk environments in 2 regions. Steps: 
5. Deploy from AWS Git CodePipeline to the AWS Beanstalk targets in each region. Alternatively you can confugure [cross region actions] (https://docs.aws.amazon.com/codepipeline/latest/userguide/actions-create-cross-region.html) in CodePipeline.
6. Deploy Cloudfront Web distribution with 2 custom origins of Elastic Beanstalk FQDN's, associate ACM certifiate and WAF ACL with it. Add your domains that was on the SSL certificate (such as example.com and www.example.com) to Alternative Domain Names (CNAMEs). Select origin behavior policy Redirect HTTP to HTTPS for each origin. Leave origin settings as default.
7. Deploy AWSRoute 53 hosted zone with latency based routing record sets for 2 beanstalk environments in 2 regions. Detailed steps:
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-failover-alias.html
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-latency-alias.html 
8. Deploy [AWS WAF Security Automations] (https://github.com/afrovera/aws-waf-security-automations/tree/master/deployment) in 2 regions.
9. Deploy Cloudfront Web distribution with 2 custom origins of Elastic Beanstalk FQDN's, associate ACM certifiate and WAF ACL with it. Add your domains that was on the SSL certificate (such as example.com and www.example.com) to Alternative Domain Names (CNAMEs). Select origin behavior policy Redirect HTTP to HTTPS for each origin.
10. Deploy [Threat detection stack] (https://github.com/afrovera/aws-scaling-threat-detection-workshop/tree/master/templates) in 2 regions. 
11. Deploy [AWS CIS Benchmark stack] (https://github.com/afrovera/quickstart-compliance-cis-benchmark/tree/master/templates) in 2 regions.

Steps to test
------------------

1. The application contacts EC2 Metadata URL and returns an availability zone from the backend instance. Each time the app responds with "hello" and back-end AZ. Test by performing GET against the /hello endpoint.
2. The application is spread across 2 AWS regions. Test by performing GET against /hello endpoint from different regions from an EC2 instance in each region. The app will return "hello" and AZ of the closest region.
3. Terminate an instance within the AZ. This will trigger the creation of another instance in the same AZ, but the availability of the service shouldn’t be interrupted. Bonus: use Chaos monkey.
4. Inspect AWS Inspector reports. To perform security testing, use an authorized platform to simulate attacks. This should generate GuardDuty findings and WAF metrics.
5. Evaluate audits of CIS Config rules.

What Should I Do Before Running My Project in Production?
------------------

You should regularly apply patches and review security best practices for the dependencies used by your application. Use these security best practices to update your sample code and maintain your project in a production environment:

1. Track ongoing security announcements and updates for your framework.
2. Before you deploy your project, follow the best practices developed for your framework.
3. Review dependencies for your framework on a regular basis and update as needed.
