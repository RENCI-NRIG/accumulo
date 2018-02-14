# Apache Accumulo in Docker

This work has been inspired by:

- ExoGENI Recipes: [RENCI-NRIG/exogeni-recipes/accumulo](https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/accumulo/accumulo_exogeni_postboot.sh)
- Oracle Java 8: [binarybabel/docker-jdk](https://github.com/binarybabel/docker-jdk/blob/master/src/centos.Dockerfile)
- CentOS 7 base image: [krallin/tini-images](https://github.com/krallin/tini-images)


### What Is Apache Accumulo?

Apache Accumulo is a key/value store based on the design of Google's [BigTable](https://research.google.com/archive/bigtable.html). Accumulo stores its data in [Apache Hadoop](https://hadoop.apache.org/)'s HDFS and uses [Apache Zookeeper](https://zookeeper.apache.org/) for consensus. While many users interact directly with Accumulo, several [open source projects](https://accumulo.apache.org/related-projects) use Accumulo as their underlying store.

See [official documentation](http://accumulo.apache.org) for more information.

## How to use this image

### Build locally


```
$ docker build -t renci/accumulo:1.8.1 ./1.8.1/
  ...
$ docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
renci/accumulo        1.8.1               b392c045e54f        3 minutes ago       1.95GB
...
```

### From Docker Hub

Automated builds are generated at: [https://hub.docker.com/u/renci](https://hub.docker.com/u/renci/dashboard/) and can be pulled as follows.

```
$ docker pull renci/accumulo:1.8.1
```

## Example

Using the provided [`docker-compose.yml`](docker-compose.yml) file to stand up a seven node Accumulo cluster that includes an `accumulomaster`, `namenode`, `resourcemanager`, two workers (`worker1` and `worker2`) and two [ZooKeeper](https://hub.docker.com/r/renci/zookeeper/) nodes (`zoo` and `zoo2`).

TODO - Add diagram

The nodes will use the defintions found in the [site-files](site-files) directory to configure the cluster. These files can be modified as needed to configure your cluster as needed at runtime.

A docker volume named `hadoop-public` is also created to allow the nodes to exchange SSH key information between themselves on startup.

```yaml
version: '3.1'

services:

  accumulomaster:
    image: renci/accumulo:1.8.1
    depends_on:
      - namenode
    container_name: accumulomaster
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: accumulomaster
    networks:
      - accumulo
    ports:
      - '9995:9995'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'true'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'false'
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'false'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 accumulomaster
      ZOOKEEPER_NODES: zoo1 zoo2

  namenode:
    image: renci/accumulo:1.8.1
    depends_on:
      - zoo1
    container_name: namenode
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: namenode
    networks:
      - accumulo
    ports:
      - '50070:50070'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'false'
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'true'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'false'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 accumulomaster
      ZOOKEEPER_NODES: zoo1 zoo2

  resourcemanager:
    image: renci/accumulo:1.8.1
    depends_on:
      - namenode
    container_name: resourcemanager
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: resourcemanager
    networks:
      - accumulo
    ports:
      - '8042:8042'
      - '8088:8088'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'false'
      IS_NODE_MANAGER: 'true'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'false'
      IS_RESOURCE_MANAGER: 'true'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 accumulomaster
      ZOOKEEPER_NODES: zoo1 zoo2

  worker1:
    image: renci/accumulo:1.8.1
    depends_on:
      - namenode
    container_name: worker1
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: worker1
    networks:
      - accumulo
    ports:
      - '9997:9997'
      - '50075:50075'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'true'
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'true'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 accumulomaster
      ZOOKEEPER_NODES: zoo1 zoo2

  worker2:
    image: renci/accumulo:1.8.1
    depends_on:
      - namenode
    container_name: worker2
    volumes:
      - hadoop-public:/home/hadoop/public
      - ./site-files:/site-files
    restart: always
    hostname: worker2
    networks:
      - accumulo
    ports:
      - '50076:50075'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'true'
      IS_NODE_MANAGER: 'false'
      IS_NAME_NODE: 'false'
      IS_SECONDARY_NAME_NODE: 'false'
      IS_DATA_NODE: 'true'
      IS_RESOURCE_MANAGER: 'false'
      CLUSTER_NODES: namenode resourcemanager worker1 worker2 accumulomaster
      ZOOKEEPER_NODES: zoo1 zoo2

  zoo1:
    image: renci/zookeeper:3.4.11
    container_name: zoo1
    restart: always
    hostname: zoo1
    networks:
      - accumulo
    ports:
      - 2181:2181
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888 server.2=zoo2:2888:3888

  zoo2:
    image: renci/zookeeper:3.4.11
    container_name: zoo2
    restart: always
    hostname: zoo2
    networks:
      - accumulo
    ports:
      - 2182:2181
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zoo1:2888:3888 server.2=0.0.0.0:2888:3888

networks:
  accumulo:

volumes:
  hadoop-public:
```

Run with docker-compose.

```
$ docker-compose up -d
```

After a few moments the containers should be configured and running.

```
$ docker-compose ps
     Name                    Command               State                            Ports
-------------------------------------------------------------------------------------------------------------------
accumulomaster    /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:9995->9995/tcp
namenode          /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50070->50070/tcp
resourcemanager   /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:8042->8042/tcp, 0.0.0.0:8088->8088/tcp
worker1           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50075->50075/tcp, 0.0.0.0:9997->9997/tcp
worker2           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50076->50075/tcp
zoo1              /usr/local/bin/tini -- /do ...   Up      0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp
zoo2              /usr/local/bin/tini -- /do ...   Up      0.0.0.0:2182->2181/tcp, 2888/tcp, 3888/tcp
```

Since the ports of the containers were mapped to the host the various web ui's can be observed using a local browser.

**accumulomaster container**: AccumuloMaster Web UI on port 9995

AccumuloMaster

<img width="50%" alt="AccumuloMaster" src="https://user-images.githubusercontent.com/5332509/36229442-3c383efc-11a5-11e8-8e21-6b3056c3ac58.png">


**namenode container**: NameNode Web UI on port 50070

NameNode

<img width="50%" alt="NameNode" src="https://user-images.githubusercontent.com/5332509/36229445-3c633fda-11a5-11e8-99ef-0e95a03cde2b.png">

**resource manager container**: ResourceManager/NodeManager Web UI on ports 8088 and 8042

ResourceManager

<img width="50%" alt="ResourceManager" src="https://user-images.githubusercontent.com/5332509/36229443-3c4ad09e-11a5-11e8-97bc-36cd7788b98a.png">

NodeManager

<img width="50%" alt="NodeManager" src="https://user-images.githubusercontent.com/5332509/36229444-3c56bb98-11a5-11e8-8434-f38191953528.png">

**worker1 and worker2 containers**: DataNode Web UI on ports 50075 and 50076

Worker1 DataManager

<img width="50%" alt="Worker1 DataManager" src="https://user-images.githubusercontent.com/5332509/36229446-3c736612-11a5-11e8-8c8b-359858ef0b79.png">

Worker2 DataManager

<img width="50%" alt="Worker2 DataManager" src="https://user-images.githubusercontent.com/5332509/36229447-3c7caea2-11a5-11e8-933b-964f66e79da1.png">


### References

1. [https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/accumulo/accumulo_exogeni_postboot.sh](https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/accumulo/accumulo_exogeni_postboot.sh)
2. Hadoop configuration files
	- Common: [hadoop-common/core-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/core-default.xml)
	- HDFS: [hadoop-hdfs/hdfs-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)
	- MapReduce: [hadoop-mapreduce-client-core/mapred-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)
	- Yarn: [hadoop-yarn-common/yarn-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
	- Deprecated Properties: [hadoop-common/DeprecatedProperties.html](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
