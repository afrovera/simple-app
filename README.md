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

These steps assume that you have an AWS credentials with minimum required proveledges and domain name to test the AWS-managed SSL configuraiton.

1. Create CodePipeline with Git source.
2. Create Infrastructure with AWS Beanstalk in 2 regions.
3. Deploy CodePipeline to the AWS Beanstalk targets.
4. Deploy API Gateway proxy endpoint.
5. Deploy Route 53 hosted zone.
6  Deploy ACM certificate for API Gateway endpoint.
7. Deploy AWS Security Automations.
8. Deploy AWS Inspector scheduled scans.
9. Deploy AWS Security best Practices.

Steps to test
------------------

1. The application contacts EC2 Metadata URL and returns an availibility zone from the backend instnace. Each time the app responds with "hello" and back-end AZ. Test by performing GET against the /hello endpoint.
2. The application is spread across 2 AWS regions. Test by performing GET against /hello endpoint from different regions from an EC2 instance in each region. The app will return "hello" and AZ of the closest region.
3. Terminate an instance within the AZ. This will trigger the creation of another instance in the same AZ, but the availability of the service shouldn’t be interrupted. Bonus: use Chaos monkey.
4. Inspect AWS Inspector reports. To perform security testing, use an authorized platform simulate attacks. This should generate GuardDuty findings. 

What Should I Do Before Running My Project in Production?
------------------

You should regularly apply patches and review security best practices for the dependencies used by your application. Use these security best practices to update your sample code and maintain your project in a production environment:

1. Track ongoing security announcements and updates for your framework.
2. Before you deploy your project, follow the best practices developed for your framework.
3. Review dependencies for your framework on a regular basis and update as needed.
