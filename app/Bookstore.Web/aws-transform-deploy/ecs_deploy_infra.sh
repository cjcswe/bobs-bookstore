#!/bin/bash

# Copyright 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.

set -e

# Constants
TEMPLATE_FILE_PATH=""
INSTANCE_ID_FILE="instance_id_from_infra_deployment.config"
GITIGNORE_PATH=".gitignore"

# Default values
# Common defaults
DEFAULT_REGION="{{region}}"

# ECS-specific defaults
DEFAULT_RESOURCE_PREFIX="{{resource_prefix}}"
DEFAULT_VPC_ID="{{vpc_id}}"
DEFAULT_PUBLIC_SUBNET_IDS="{{public_subnet_ids}}"
DEFAULT_PRIVATE_SUBNET_IDS="{{private_subnet_ids}}"
DEFAULT_ALB_ARN="{{alb_arn}}"
DEFAULT_ALB_SECURITY_GROUP_ID="{{alb_security_group_id}}"
DEFAULT_ECS_CLUSTER_NAME="{{ecs_cluster_name}}"
DEFAULT_ECS_SECURITY_GROUP_ID="{{ecs_security_group_id}}"
DEFAULT_CERTIFICATE_ARN="{{certificate_arn}}"
DEFAULT_ALB_LISTENER_PORT="{{alb_listener_port}}"

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            --deployment-type)
                DEPLOYMENT_TYPE="$2"
                shift 2
                ;;
            --stack-name)
                STACK_NAME="$2"
                shift 2
                ;;
            --region)
                REGION="$2"
                shift 2
                ;;
            --skip-assume-role)
                SKIP_ASSUME_ROLE=true
                shift
                ;;
            # ECS-specific parameters
            --resource-prefix)
                RESOURCE_PREFIX="$2"
                shift 2
                ;;
            --vpc-id)
                VPC_ID="$2"
                shift 2
                ;;
            --public-subnet-ids)
                PUBLIC_SUBNET_IDS="$2"
                shift 2
                ;;
            --private-subnet-ids)
                PRIVATE_SUBNET_IDS="$2"
                shift 2
                ;;
            --alb-arn)
                ALB_ARN="$2"
                shift 2
                ;;
            --alb-security-group-id)
                ALB_SECURITY_GROUP_ID="$2"
                shift 2
                ;;
            --ecs-cluster-name)
                ECS_CLUSTER_NAME="$2"
                shift 2
                ;;
            --ecs-security-group-id)
                ECS_SECURITY_GROUP_ID="$2"
                shift 2
                ;;
            --certificate-arn)
                CERTIFICATE_ARN="$2"
                shift 2
                ;;
            --alb-listener-port)
                ALB_LISTENER_PORT="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Function to handle future deployment types
validate_deployment_type() {
    local deployment_type=$1
    case $deployment_type in
        "ecs")
            TEMPLATE_FILE_PATH="ecs_infra_template.yml"
            ;;
        *)
            write_log "ERROR" "Unsupported deployment type: $deployment_type"
            write_log "ERROR" "Currently supported types: ecs"
            exit 1
            ;;
    esac
}

# Logging and display functions
write_log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local severity=$1
    local message=$2
    echo "[$timestamp] [$severity] $message"
}

show_usage() {
    write_log "INFO" "Usage: 
    ./deploy_infra.sh --deployment-type ecs [options]

Common Parameters:
    --deployment-type        : (Required) Type of deployment (currently supports: ecs)
    --stack-name            : (Optional) Name for the CloudFormation stack
    --region                : (Optional) AWS region for deployment. Default: ${DEFAULT_REGION}
    --skip-assume-role      : (Optional) Skip assuming the deployment role

ECS Parameters:
    --resource-prefix       : (Required) Prefix for resource names
    --vpc-id               : (Optional) ID of the VPC for ECS deployment
    --public-subnet-ids    : (Optional) Comma-separated list of public subnet IDs
    --private-subnet-ids   : (Optional) Comma-separated list of private subnet IDs
    --alb-arn             : (Optional) ARN of existing Application Load Balancer
    --alb-security-group-id: (Optional) ID of existing ALB security group
    --ecs-cluster-name     : (Optional) Name of existing ECS cluster
    --ecs-security-group-id: (Optional) ID of existing ECS security group
    --certificate-arn      : (Optional) ARN of ACM certificate for HTTPS listener
    --alb-listener-port    : (Optional) Port for ALB listener. Default: 80 (HTTP) or 443 (HTTPS)

This script will:    
    Validate all input parameters
    Deploy the stack and wait for completion
    Write the infrastructure details to file '$INSTANCE_ID_FILE'
    Provide detailed error information and suggestions if deployment fails
    Show successful completion message if deployment succeeds"
}

initialize_parameters() {
    # Set region to default if not provided
    REGION=${REGION:-$DEFAULT_REGION}

    # Generate stack name if not provided
    if [ -z "$STACK_NAME" ]; then
        STACK_NAME="AWSTransform-Deploy-Infra-Stack-${RESOURCE_PREFIX}"
        STACK_NAME=$(echo "$STACK_NAME" | sed -e 's/[^a-zA-Z0-9\-]/-/g' -e 's/--*/-/g')
    fi

    # Validate required parameters based on deployment type
    validate_deployment_parameters
}

validate_deployment_parameters() {
    local missing_params=()

    case $DEPLOYMENT_TYPE in
        "ecs")
            if [ -z "$RESOURCE_PREFIX" ]; then
                missing_params+=("RESOURCE_PREFIX")
            fi
            ;;
    esac

    if [ ${#missing_params[@]} -ne 0 ]; then
        write_log "ERROR" "Missing required parameters: ${missing_params[*]}"
        show_usage
        exit 1
    fi
}

assume_role() {
    local role_arn="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/${RESOURCE_PREFIX}-Deployment-Role"
    write_log "INFO" "Assuming role: $role_arn"
    
    local credentials=$(aws sts assume-role --role-arn "$role_arn" --role-session-name "DeploymentSession" --output json)
    
    if [ $? -ne 0 ]; then
        write_log "ERROR" "Failed to assume role. Please verify that:"
        write_log "ERROR" "1. The role 'AWSTransformDotNET-Infra-Deployment-Role' exists in your account"
        write_log "ERROR" "2. Your IAM user/role has permission to assume this role"
        write_log "ERROR" "3. The role trust policy allows your IAM user/role to assume it"
        exit 1
    fi

    export AWS_ACCESS_KEY_ID=$(echo "$credentials" | jq -r '.Credentials.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo "$credentials" | jq -r '.Credentials.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo "$credentials" | jq -r '.Credentials.SessionToken')
}

get_common_error_solution() {
    local error_message="$1"
    
    case "$error_message" in
        *"role cannot be assumed"*)
            echo "Check IAM role permissions and trust relationships"
            ;;
        *"VPC"*)
            echo "Verify VPC ID exists and is in the correct region"
            ;;
        *"ECS cluster"*)
            echo "Verify ECS cluster name is correct and the cluster exists"
            ;;
        *"certificate"*)
            echo "Ensure the ACM certificate ARN is valid and in the correct region"
            ;;
        *)
            echo "Review CloudFormation documentation and check AWS Console for more details"
            ;;
    esac
}

add_to_gitignore() {
    local file_to_ignore="$1"
    
    if [ -f "$GITIGNORE_PATH" ]; then
        if ! grep -q "^$file_to_ignore$" "$GITIGNORE_PATH"; then
            echo "$file_to_ignore" >> "$GITIGNORE_PATH"
        fi
    else
        echo "$file_to_ignore" > "$GITIGNORE_PATH"
    fi
}

deploy_stack() {
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" 2>/dev/null; then
        write_log "WARN" "Stack $STACK_NAME already exists."
        
        # Get current stack outputs
        local outputs
        outputs=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query 'Stacks[0].Outputs' --output json)
        
        write_log "INFO" "Current stack has the following CFN outputs:"
        echo "$outputs"

        read -r -p "Do you want to delete the existing stack? (y/n) " REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            write_log "INFO" "Stack deletion cancelled by user"
            exit 0
        fi

        write_log "WARN" "Deleting stack $STACK_NAME..."
        aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION"
        write_log "WARN" "Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION"
        write_log "SUCCESS" "Stack deletion completed"
    fi

    write_log "SUCCESS" "Deploying stack: $STACK_NAME"

    # Create parameters array
    local parameters=(
        "ParameterKey=ResourcePrefix,ParameterValue=$RESOURCE_PREFIX"
        "ParameterKey=VpcId,ParameterValue=${VPC_ID:-''}"
        "ParameterKey=PublicSubnetIds,ParameterValue='${PUBLIC_SUBNET_IDS:-''}'"
        "ParameterKey=PrivateSubnetIds,ParameterValue='${PRIVATE_SUBNET_IDS:-''}'"
        "ParameterKey=AlbArn,ParameterValue=${ALB_ARN:-''}"
        "ParameterKey=AlbSecurityGroupId,ParameterValue=${ALB_SECURITY_GROUP_ID:-''}"
        "ParameterKey=EcsClusterName,ParameterValue=${ECS_CLUSTER_NAME:-''}"
        "ParameterKey=EcsSecurityGroupId,ParameterValue=${ECS_SECURITY_GROUP_ID:-''}"
        "ParameterKey=CertificateArn,ParameterValue=${CERTIFICATE_ARN:-''}"
        "ParameterKey=AlbListenerPort,ParameterValue=${ALB_LISTENER_PORT:-0}"
    )

    # Create stack
    if aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body "file://$TEMPLATE_FILE_PATH" \
        --parameters "${parameters[@]}" \
        --capabilities CAPABILITY_IAM \
        --region "$REGION" \
        --tags Key=CreatedFor,Value=AWSTransformDotNET; then

        write_log "WARN" "Waiting for stack creation to complete..."
        aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"

        if [ $? -eq 0 ]; then
            write_log "SUCCESS" "Stack deployment completed successfully!"
            
            # Get and save stack outputs
            aws cloudformation describe-stacks \
                --stack-name "$STACK_NAME" \
                --region "$REGION" \
                --query 'Stacks[0].Outputs' \
                --output json > "$INSTANCE_ID_FILE"

            write_log "INFO" "Infrastructure details written to $INSTANCE_ID_FILE"
            add_to_gitignore "$INSTANCE_ID_FILE"
            
            write_log "INFO" "Please refer to README.md and deploy.sh in order to deploy the application to this infrastructure."
        else
            write_log "ERROR" "Stack deployment failed"
            aws cloudformation describe-stack-events \
                --stack-name "$STACK_NAME" \
                --region "$REGION" \
                --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]' \
                --output json | jq -r '.[] | "Failed resource: \(.LogicalResourceId)\nReason: \(.ResourceStatusReason)"' | \
                while IFS= read -r line; do
                    write_log "ERROR" "$line"
                done
            exit 1
        fi
    else
        write_log "ERROR" "Failed to initiate stack creation"
        exit 1
    fi
}

check_dependencies() {
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        write_log "ERROR" "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        write_log "ERROR" "jq is not installed. Please install it first."
        exit 1
    fi
}

main() {
    check_dependencies

    # Parse command line arguments
    parse_arguments "$@"

    # Validate deployment type
    validate_deployment_type "$DEPLOYMENT_TYPE"

    # Initialize and validate parameters
    initialize_parameters

    # Assume role if not skipped
    if [ "$SKIP_ASSUME_ROLE" != "true" ]; then
        assume_role
    fi

    # Deploy the stack
    deploy_stack
}

# Start script execution
main "$@"