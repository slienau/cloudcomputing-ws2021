openstack security group create open-all

openstack security group rule create --egress --proto tcp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --egress --proto udp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --egress --proto icmp --remote-ip 0.0.0.0/0 open-all

openstack security group rule create --ingress --proto tcp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --ingress --proto udp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all

openstack security group rule create --ingress --proto icmp --remote-ip 0.0.0.0/0 open-all

ssh-keygen -b 2048 -t rsa -f ./id_openstack -q -N ""

IP=$(gcloud compute instances list | grep controller | awk '{print $5}' | cut -d ',' -f 1)

scp -i ~/.ssh/id_rsa ./id_openstack $USER@$IP:/home/$USER/.ssh

ssh -i ~/.ssh/id_rsa  $USER@$IP 'chmod 400 ~/.ssh/id_openstack'

openstack keypair create --public-key ./id_openstack.pub openstack_default_key

m1.medium  ubuntu-16.04 admin-net default

PROJECT_ID=$(openstack project list | grep admin | awk '{print $2}')

SECURITY_ID=$(openstack security group list --project $PROJECT_ID | grep default | awk '{print $2}')

openstack server create --flavor m1.medium --image ubuntu-16.04 \
    --network admin-net --security-group $SECURITY_ID \
    --key-name openstack_default_key ins1