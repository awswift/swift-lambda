#!/bin/bash

json=$(aws sts assume-role --role-arn "arn:aws:iam::786057604932:role/SwiftdaCLIRole" --role-session-name "swiftda-cli-dev")
AWS_ACCESS_KEY_ID=$(echo "$json" | jq  '.Credentials.AccessKeyId' --raw-output)
AWS_SECRET_ACCESS_KEY=$(echo "$json" | jq  '.Credentials.SecretAccessKey' --raw-output)
AWS_SESSION_TOKEN=$(echo "$json" | jq  '.Credentials.SessionToken' --raw-output)

echo "export AWS_ACCESS_KEY_ID=\"$AWS_ACCESS_KEY_ID\""
echo "export AWS_SECRET_ACCESS_KEY=\"$AWS_SECRET_ACCESS_KEY\""
echo "export AWS_SESSION_TOKEN=\"$AWS_SESSION_TOKEN\""
