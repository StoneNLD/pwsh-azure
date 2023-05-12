#!/bin/bash

# Set the Azure CLI environment variables
export AZURE_CLIENT_ID=d2c8328b-3f45-4338-846e-7aba4e53475c
export AZURE_CLIENT_SECRET=<your_client_secret>
export AZURE_TENANT_ID=<your_tenant_id>

# Get the device code and login URL
device_code_result=$(az account get-access-token --query "{ device_code: device_code, login_url: verification_uri }")
device_code=$(echo $device_code_result | jq -r .device_code)
login_url=$(echo $device_code_result | jq -r .login_url)

# Display the device code and login URL to the user
echo "Please visit $login_url and enter the following code: $device_code"

# Wait for the user to enter the code and press enter
read -p "Press enter to continue..."

# Authenticate using the device code
az login --use-device-code

# Display the authenticated user
az account show --query "{name: user.name, type: user.type}"
