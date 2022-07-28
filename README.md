# Elastic Cloud on Kubernetes(ECK)
This repository contains deployment of ECK in Kind cluster with different options.

# Installation
Easy installation available with the script [install.sh](install.sh). Installation script has been tested for MacOSX but can work with Linux as well.

## Pre-requisites
Installation script expects following tools to be available.
- kind
- kubectl
- envsubst

## Running the installation
Installation expect two environment variables `ELASTIC_PASSWORD` and `DEVELOPER_PASSWORD` to be set. These can be set as part of the script execution as 
follows. User `elastic` will be configured with password  `ELASTIC_PASSWORD` and this user is the superuser. User `developer` will be configured with the
password `DEVELOPER_PASSWORD` and this user is assigned to a role `demo` which is created as part of the installation.

```bash
ELASTIC_PASSWORD=password DEVELOPER_PASSWORD=password ./install.sh
```

# Access to ES and Kibana
Port-foewarding is required to access the ES or the Kibana.

```bash
# Port forward for ES and Kibana
kubectl port-forward svc/kibana-kb-http 5601:5601
kubectl port-forward svc/demo-es-master 9200:9200
```

Node information [https://127.0.0.1:9200/_nodes](https://127.0.0.1:9200/_nodes)
Kibana [http://127.0.0.1:5601/](http://127.0.0.1:5601/)

# Concepts

## Set Elastic User Password
ES creates the user `elastic` and generate a random  password by default. However if a secret is defined with username `elastic` and that secret included in
Elasticsearch file realm configuration then the password in the secret will be used configuring the `elastic` user. 

## Specific Index Access to Users
The user `developer` has full permission for the index `demo`. This is defined in the role `demo` in the [manifest-secret.yaml](manifest-secret.yaml). 
Elasticsearch support fine grained control for the permission more information is available in official documentation [security-privileges](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-privileges.html). Manging roles and users in ECK available in official documentation [k8s-users-and-roles](https://www.elastic.co/guide/en/cloud-on-k8s/master/k8s-users-and-roles.html)

## Node Set with Attributes
Node set can be created with attributes. Node group [datax](./manifest-es.yaml) is created with the node attribute `type:demo`. These attributes can be used
to target the nodes when creating the index.


# Examples

## Creating demo index
Following commands creates demo index. Developer user can only create/manage demo index as per the role demo permission.

```sh
curl -XPUT -k -u "developer:<DEVELOPER_PASSWORD>" -H "Content-Type: application/json" -d '{"settings":{"index":{"number_of_shards": 2,"number_of_replicas": 2}}}' https://127.0.0.1:9200/demo
```

## Create demo index on specific node set
This Elastic stack has nodeset `datax` with node attribute `type:demo`. Folloiwng index is created to store the index only on nodes which has the attribute.

```sh
# Create index
curl -XPUT -k -u "developer:<DEVELOPER_PASSWORD>" -H "Content-Type: application/json" -d '{"settings":{"index":{"number_of_shards": 2,"number_of_replicas": 2,"routing":{"allocation":{"require":{"type": "demo"}}}}}}' https://127.0.0.1:9200/demo

# Add document to the index
curl -XPOST -k -u "developer:<DEVELOPER_PASSWORD>" -H "Content-Type: application/json" -d '{"city":"NY"}' https://127.0.0.1:9200/demo/_doc/1

# Check shard allocation. No shards are in master node set due to routing
curl -k -u "elastic:<ELASTIC_PASSWORD>" https://127.0.0.1:9200/_cat/shards/demo
```