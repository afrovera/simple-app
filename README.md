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


About this solution
--------------------

I made a modification to the Java controller source code to call EC2 metadata URL when you hit /hello and return the backend AZ to the client for the purpose of this assignment. If you hit /hello 3 times when ELB is scaled to 3 back-ends, it will return 3 different AZs. For the purpose of this assignment the CFT tempalte is designed to scale to 3 backends during bootstrappng process. To bootstrap the environment scaled out to any specific number of backends modify the parameter of the CFT template to a minimum desired number. The app is build and deployed through CodePipeline to 2 Elastic Beanstalk applications which can be auto-scaled to fault tolerance tests. The CodePileline has integrated rollbacks and re-deployment options integrated by default. There is no SSH or password access to the Beanstalk backends since it has systems manager (SSM) agent already installed by default for remote access. App was scanned with a app.snyk.io utility and has 5 high severity vulnerabilities due to the outdated Spring framework and Tomcat version. Amazon Inspector scanner confirmed the findings. Remediation is to upgrade Spring and Tomcat immediately. Future consideration is to integrate static code analysis into the CodePipeline stages during the releases to scan for vulnerabilities before deployments take place.

Link to the [Scan reports](https://github.com/afrovera/devsecops/tree/master/reports).

Steps to deploy
------------------

These steps assume that you have an AWS credentials with minimum required privileges to deploy the stack. The number of services deployed by this project requires very broad IAM permissions, I recommend using MFA-protected IAM use/role with such policy.

CodePipeline stack is designed to deploy to Elastic Beantalk which comes in 2 versions, with multi-subnet VPC and without VPC. After the deployment of the stack, Beanstalk environments can be auto-scaled for the purpose of failue tolerance testing. 

1. Prepare AWS Account by creating an S3 bucket for storing CodeBuild Artifacts and Amazon-issued SSL certificate for securing the website (optional). 

*Create EC2 keypair in 2 regions (default opstest).
aws ec2 create-key-pair --key-name opstest --region us-east-1
aws ec2 create-key-pair --key-name opstest --region eu-west-1

*Create an S3 bucket for storing CodeBuild Artifacts (default devsecops-opstest).
aws s3api create-bucket --bucket devsecops-opstest --region us-east-1
aws s3api create-bucket --bucket devsecops-opstest --region eu-west-1

Optional extra
------------------
*Amazon-issued SSL certificate for securing the website in 2 regions (replace www.example.com with actual domain name).
aws acm request-certificate --domain-name example.com --validation-method DNS --subject-alternative-names www.example.com --region us-east-1
aws acm request-certificate --domain-name example.com --validation-method DNS --subject-alternative-names www.example.com --region eu-west-1

*[Validate Certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html#gs-acm-use-dns) by creating CNAME record for the domain and wait for certificate to be issued (approximately 5 minutes with Route 53).

*If you canont update DNS records for the domain, use e-mail validation.
aws acm request-certificate --domain-name example.com --validation-method EMAIL --subject-alternative-names www.example.com --region us-east-1
aws acm request-certificate --domain-name example.com --validation-method EMAIL --subject-alternative-names www.example.com --region eu-west-1

2. (Optional) Create [VPC Stack](https://github.com/afrovera/quickstart-aws-vpc/blob/master/templates/aws-vpc.template) with Public/Private subnets in multiple availibility zones.
3. Create [Code Pipeline Stacks](https://github.com/afrovera/devsecops/tree/master/templates) in 2 regions with Git source of this repo.
4. Release the PipeLine change.
5. Deploy from AWS Git CodePipeline to the AWS Beanstalk targets in each region. Alternatively you can confugure [cross region actions](https://docs.aws.amazon.com/codepipeline/latest/userguide/actions-create-cross-region.html) in CodePipeline.
6. (Optional) Deploy Cloudfront Web distribution with 2 custom origins of Elastic Beanstalk FQDN's, associate ACM certifiate and WAF ACL with it. Add your domains that was on the SSL certificate (such as example.com and www.example.com) to Alternative Domain Names (CNAMEs). Select origin behavior policy Redirect HTTP to HTTPS for each origin. Leave origin settings as default.
7. (Optional) Deploy AWSRoute 53 hosted zone with latency based routing record sets for 2 beanstalk environments in 2 regions. Detailed steps:
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-failover-alias.html
https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-values-latency-alias.html 
8. Deploy [AWS WAF Security Automations](https://github.com/afrovera/aws-waf-security-automations/tree/master/deployment) in 2 regions.
9. Associate WAF ACL and SSL certificate with Cloudfront Web distribution with 2 custom origins of Elastic Beanstalk FQDN's. Add your domains that was on the SSL certificate (such as example.com and www.example.com) to Alternative Domain Names (CNAMEs). Select origin behavior policy Redirect HTTP to HTTPS for each origin.
10. Deploy [Threat detection stack](https://github.com/afrovera/aws-scaling-threat-detection-workshop/tree/master/templates) in 2 regions. 
11. Deploy [AWS CIS Benchmark stack](https://github.com/afrovera/quickstart-compliance-cis-benchmark/tree/master/templates) in 2 regions.

Steps to test
------------------

1. The application contacts EC2 Metadata URL and returns an availability zone from the backend instance. Each time the app responds with "hello" and back-end AZ. Test by performing GET against the /hello endpoint.
2. The application is spread across 2 AWS regions. Test by performing GET against /hello endpoint from different regions from an EC2 instance in each region. The app will return "hello" and AZ of the closest region.
3. Terminate an instance within the AZ. This will trigger the creation of another instance in the same AZ, but the availability of the service shouldn’t be interrupted. Bonus: use Chaos monkey.
4. Inspect AWS Inspector reports. 

*Beanstalk instances are launched with SSM agent installed by default on 2018 Amazon LinuxAMIs. Use SSM agent to install and configure Inspector agent on Beanstalk-tagged instances.

aws ssm send-command --document-name "AmazonInspector-ManageAWSAgent" --parameters commands=["echo helloWorld"] --targets "Key=Name,Values=my_beanstalk_hosts"

*After execution of the above, create resource group, asessment template and run it.

aws inspector create-resource-group --resource-group-tags key=Name,value=my_beanstalk_hosts

aws inspector create-assessment-target --assessment-target-name ExampleAssessmentTarget --resource-group-arn arn:aws:inspector:us-west-2:123456789012:resourcegroup/0-AB6DMKnv

aws inspector create-assessment-template --assessment-target-arn arn:aws:inspector:us-west-2:123456789012:target/0-nvgVhaxX --assessment-template-name ExampleAssessmentTemplate --duration-in-seconds 180 --rules-package-arns arn:aws:inspector:us-west-2:758058086616:rulespackage/0-9hgA516p --user-attributes-for-findings key=ExampleTag,value=examplevalue

aws inspector start-assessment-run --assessment-run-name examplerun --assessment-template-arn arn:aws:inspector:us-west-2:123456789012:target/0-nvgVhaxX/template/0-it5r2S4T

To perform application and network security testing with third-party tools, use an authorized platform to simulate attacks. This should generate GuardDuty findings and WAF metrics.

5. Evaluate audits of CIS Config rules for account-wide compliance.

Fixing issues
------------------

TODO

What Should I Do Before Running My Project in Production?
------------------

You should regularly apply patches and review security best practices for the dependencies used by your application. Use these security best practices to update your sample code and maintain your project in a production environment:

1. Track ongoing security announcements and updates for your framework.
2. Before you deploy your project, follow the best practices developed for your framework.
3. Review dependencies for your framework on a regular basis and update as needed.
