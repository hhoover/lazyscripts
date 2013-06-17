
read -p "Rackspace Username: " rsusername
read -p "Rackspace Account Number: " rsddi
read -p "Rackspace API Key: " rsapikey
read -p "Region (LON/DFW/ORD): " region


export NOVA_API_KEY=rsapikey
export NOVA_USERNAME=rsusername
export NOVA_PROJECT_ID=rsddi
export NOVA_SERVICE_NAME=cloudServersOpenStack
export NOVA_VERSION=1.1
export NOVA_RAX_AUTH=1
export NOVA_URL=https://identity.api.rackspacecloud.com/v2.0/
