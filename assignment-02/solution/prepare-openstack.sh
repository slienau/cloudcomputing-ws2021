# Assuming a configured openstack cli is installed

# Create a security group
openstack security group create open-all

# The next commands are pretty self explanatory
openstack security group rule create --egress --proto tcp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --egress --proto udp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --egress --proto icmp --remote-ip 0.0.0.0/0 open-all

openstack security group rule create --ingress --proto tcp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --ingress --proto udp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --ingress --proto icmp --remote-ip 0.0.0.0/0 open-all

# Create a ssh key to deploy on the openstack vm
ssh-keygen -b 2048 -t rsa -f ./id_openstack -N ""

# List the instances, get the controller line and extract the public ip
IP=$(gcloud compute instances list | grep controller | awk '{print $5}' | cut -d ',' -f 1)

# Copy the created ssh private key to the controller vm
# Here it is assumed that the user on the controller vm has the same name as the local system user
scp -i ~/.ssh/id_rsa ./id_openstack $USER@$IP:/home/$USER/.ssh

# Changemod of the private key to read only
ssh -i ~/.ssh/id_rsa  $USER@$IP 'chmod 400 ~/.ssh/id_openstack'

# Upload the public key to openstack metadata 
openstack keypair create --public-key ./id_openstack.pub openstack_key

# Get the project id of the admin openstack project
PROJECT_ID=$(openstack project list | grep admin | awk '{print $2}')

# Get the default security group of the project id (This was due to the ambuguity in the task 3.10, the security group is not going to be used)
SECURITY_ID=$(openstack security group list --project $PROJECT_ID | grep default | awk '{print $2}')

# Create the server based on the given parameters in the task
openstack server create --flavor m1.medium --image ubuntu-16.04 \
        --network admin-net --security-group open-all \
        --key-name openstack_key ins1