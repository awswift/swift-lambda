# Required IAM Permissions

In order to operate correctly, Swiftda needs permission to access certain AWS APIs
on your behalf. If you're a solo dev and you've set up the [AWS CLI][aws-cli] using
`aws configure`, you will have unlimited access and running Swiftda from the terminal 
should work just fine. 

However, if Swiftda is running on a CI machine or your AWS access has been granted 
by your company's AWS gurus, your access may be restricted. In order to operate
fully, Swiftda requires the following permissions. They are described in an 
AWS [IAM Policy][iam-policy-ref] document in JSON format below. This policy covers
everything you need to run Swiftda's `setup`, `deploy`, `invoke` and `destroy` 
commands.

[aws-cli]: https://aws.amazon.com/cli/
[iam-policy-ref]: http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1482554544203",
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStackEvents",
                "cloudformation:DescribeStacks",
                "cloudformation:ListExports",
                "cloudformation:UpdateStack",
                "iam:AttachRolePolicy",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:DeleteRolePolicy",
                "iam:DetachRolePolicy",
                "iam:GetRole",
                "iam:PassRole",
                "iam:PutRolePolicy",
                "lambda:CreateFunction",
                "lambda:DeleteFunction",
                "lambda:GetFunction",
                "lambda:GetFunctionConfiguration",                
                "lambda:InvokeFunction",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutBucketVersioning",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```