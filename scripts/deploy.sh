#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2021 Microsoft Azure
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Variables
resourceGroupName="FirewallWithDnsProxyRG"
location="WestEurope"
deploy=1

# ARM template and parameters files
template="../templates/azuredeploy.json"
parameters="../templates/azuredeploy.parameters.json"

# SubscriptionId of the current subscription
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)

# Check if the resource group already exists
createResourceGroup() {
    rg=$1

    echo "Checking if [$rg] resource group actually exists in the [$subscriptionName] subscription..."

    if ! az group show --name "$rg" &>/dev/null; then
        echo "No [$rg] resource group actually exists in the [$subscriptionName] subscription"
        echo "Creating [$rg] resource group in the [$subscriptionName] subscription..."

        # Create the resource group
        if az group create --name "$rg" --location "$location" 1>/dev/null; then
            echo "[$rg] resource group successfully created in the [$subscriptionName] subscription"
        else
            echo "Failed to create [$rg] resource group in the [$subscriptionName] subscription"
            exit 1
        fi
    else
        echo "[$rg] resource group already exists in the [$subscriptionName] subscription"
    fi
}

# Validate the ARM template
validateTemplate() {
    resourceGroup=$1
    template=$2
    parameters=$3
    arguments=$4

    echo "Validating [$template] ARM template..."

    if [[ -z $arguments ]]; then
        error=$(az deployment group validate \
            --resource-group "$resourceGroup" \
            --template-file "$template" \
            --parameters "$parameters" \
            --query error \
            --output json)
    else
        error=$(az deployment group validate \
            --resource-group "$resourceGroup" \
            --template-file "$template" \
            --parameters "$parameters" \
            --arguments $arguments \
            --query error \
            --output json)
    fi

    if [[ -z $error ]]; then
        echo "[$template] ARM template successfully validated"
    else
        echo "Failed to validate the [$template] ARM template"
        echo "$error"
        exit 1
    fi
}

# Deploy ARM template
deployTemplate() {
    resourceGroup=$1
    template=$2
    parameters=$3
    arguments=$4

    if [ $deploy != 1 ]; then
        return
    fi
    # Deploy the ARM template
    echo "Deploying ["$template"] ARM template..."

    if [[ -z $arguments ]]; then
         az deployment group create \
            --resource-group $resourceGroup \
            --template-file $template \
            --parameters $parameters 1>/dev/null
    else
         az deployment group create \
            --resource-group $resourceGroup \
            --template-file $template \
            --parameters $parameters \
            --parameters $arguments 1>/dev/null
    fi

     az deployment group create \
        --resource-group $resourceGroup \
        --template-file $template \
        --parameters $parameters 1>/dev/null

    if [[ $? == 0 ]]; then
        echo "["$template"] ARM template successfully provisioned"
    else
        echo "Failed to provision the ["$template"] ARM template"
        exit -1
    fi
}

# Create Resource Group
createResourceGroup "$resourceGroupName"

# Deploy JMeter Test Harness
deployTemplate \
    "$resourceGroupName" \
    "$template" \
    "$parameters"