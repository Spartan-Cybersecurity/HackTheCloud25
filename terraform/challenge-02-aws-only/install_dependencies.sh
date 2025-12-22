#!/bin/bash

# Script to install Lambda dependencies and create deployment packages
# This script prepares the Lambda functions for deployment

echo "🚀 Installing Lambda dependencies for Challenge-02-AWS-Only..."

# Create temporary directory for Lambda packages
mkdir -p lambda_packages

# Install dependencies for JWT Authorizer Lambda
echo "📦 Installing JWT Authorizer dependencies..."
pip3 install -r requirements.txt -t lambda_packages/jwt_authorizer/ --no-deps
cp lambda_authorizer.py lambda_packages/jwt_authorizer/

# Create JWT Authorizer deployment package
cd lambda_packages/jwt_authorizer
zip -r ../../jwt_authorizer.zip .
cd ../..

# Install dependencies for ReadDataPatience Lambda (only uses boto3 which is included)
echo "📦 Creating ReadDataPatience package..."
mkdir -p lambda_packages/read_data_patience
cp lambda_read_data_patience.py lambda_packages/read_data_patience/

# Create ReadDataPatience deployment package
cd lambda_packages/read_data_patience
zip -r ../../read_data_patience.zip .
cd ../..

# Clean up temporary directories
rm -rf lambda_packages

echo "✅ Lambda deployment packages created successfully!"
echo "   - jwt_authorizer.zip"
echo "   - read_data_patience.zip"
echo ""
echo "🔧 Ready for terraform apply!"
