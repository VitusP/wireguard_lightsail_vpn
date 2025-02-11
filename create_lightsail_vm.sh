#!/bin/zsh
KEYPAIRFILE="$HOME/.ssh/id_rsa.pub"
KEYPAIRNAME=$(basename -s '.pub' ${KEYPAIRFILE})

# MACHINENAME and REGION are now passed as arguments
MACHINENAME=$1
REGION=$2

# Check if MACHINENAME and REGION are provided
if [[ -z ${MACHINENAME} || -z ${REGION} ]]; then
    echo "Usage: $0 <MACHINENAME> <REGION>"
    echo "Error: MACHINENAME and REGION must be provided."
    exit 1
fi

OS='ubuntu_22_04'
PORT='41194'


# Verify the key file exists
if [[ ! -f ${KEYPAIRFILE} ]]; then
    echo "SSH key file not found: ${KEYPAIRFILE}"
    echo "Please generate an SSH key pair using: ssh-keygen -t rsa"
    exit 1
fi

# upload keypair - using the public key content directly
aws lightsail import-key-pair \
    --region ${REGION} \
    --key-pair-name ${KEYPAIRNAME} \
    --public-key "$(cat ${KEYPAIRFILE})"

# Get the cheapest bundle
CHEAPBUNDLE=$(echo `aws lightsail get-bundles --query 'bundles[0].bundleId' --region ${REGION} --output text` | tr -d '"')
echo "Found the cheapest bundle ${CHEAPBUNDLE}"

# Create the instance
echo "Creating the instance"
aws lightsail create-instances \
    --instance-names ${MACHINENAME} \
    --region ${REGION} \
    --availability-zone  ${REGION}a \
    --blueprint-id ${OS} \
    --bundle-id ${CHEAPBUNDLE} \
    --key-pair-name ${KEYPAIRNAME}

# Wait a minute then grab the IP
echo "Waiting for instance to be ready..."
sleep 60
EXTERNALIP=$(aws lightsail get-instance --instance-name ${MACHINENAME} --region ${REGION} --query 'instance.publicIpAddress' --output text)
echo $EXTERNALIP

# Configure Lightsail Firewall.
echo "Configuring Firewall"
aws lightsail put-instance-public-ports \
    --instance-name ${MACHINENAME} \
    --region ${REGION} \
    --port-infos '[{"fromPort": 41194, "toPort": 41194, "protocol": "udp"}, {"fromPort": 22, "toPort": 22, "protocol": "tcp"}]'

# Print out the IP so we can ssh to it
echo "Ready to connect to ubuntu@${EXTERNALIP}"
