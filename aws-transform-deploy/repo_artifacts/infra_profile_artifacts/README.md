# AWS Transform Deployment Template to Set Up Deployment Profile

### Prerequisites
1. Admin-level permissions on your AWS account to manage IAM Roles, IAM Instance Profiles, and CloudFormation stacks.
2. AWS credentials properly configured via either:
    - Environment variables (e.g. `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`)
    - AWS credentials file (`~/.aws/credentials`)
      See https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html for detailed setup instructions
3. **Review the CloudFormation template** `infra_profile_artifacts.yml` before deployment.

### Deploy CloudFormation stack to create IAM roles and S3 bucket if needed

```
aws cloudformation deploy --template-file infra_profile_artifacts.yml --stack-name atx-deploy-infra-profile-artifacts --capabilities CAPABILITY_NAMED_IAM --tags CreatedBy=AWSTransform
```