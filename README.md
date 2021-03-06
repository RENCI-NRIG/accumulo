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

## Example: Seven node cluster

Using the provided [`docker-compose.yml`](docker-compose.yml) file to stand up a seven node Accumulo cluster that includes an `accumulomaster`, `namenode`, `resourcemanager`, two workers (`worker1` and `worker2`) and two [ZooKeeper](https://hub.docker.com/r/renci/zookeeper/) nodes (`zoo` and `zoo2`).

Accumulo docker network and container port mapping (specific network values subject to change based on system):

<img width="80%" alt="Accumulo Docker Network" src="https://user-images.githubusercontent.com/5332509/36426229-6b414812-1617-11e8-8527-5dfd96665d77.png">

The nodes will use the definitions found in the [site-files](site-files) directory to configure the cluster. These files can be modified as needed to configure your cluster as needed at runtime.

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
      - '8088:8088'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'false'
      IS_NODE_MANAGER: 'false'
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
      - '8042:8042'
      - '50075:50075'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'true'
      IS_NODE_MANAGER: 'true'
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
      - '8043:8042'
      - '50076:50075'
    environment:
      ACCUMULO_MASTER: accumulomaster
      IS_ACCUMULO_MASTER: 'false'
      ACCUMULO_WORKERS: worker1 worker2
      IS_ACCUMULO_WORKER: 'true'
      IS_NODE_MANAGER: 'true'
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

### Start the cluster 

Using `docker-compose`

```
$ docker-compose up -d
```

After a few moments all containers will be running and should display in a `ps` call.

```
$ docker-compose ps
     Name                    Command               State                           Ports
-----------------------------------------------------------------------------------------------------------------
accumulomaster    /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:9995->9995/tcp
namenode          /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50070->50070/tcp
resourcemanager   /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:8042->8042/tcp, 0.0.0.0:8088->8088/tcp
worker1           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50075->50075/tcp
worker2           /usr/local/bin/tini -- /do ...   Up      22/tcp, 0.0.0.0:50076->50075/tcp
zoo1              /usr/local/bin/tini -- /do ...   Up      0.0.0.0:2181->2181/tcp, 2888/tcp, 3888/tcp
zoo2              /usr/local/bin/tini -- /do ...   Up      0.0.0.0:2182->2181/tcp, 2888/tcp, 3888/tcp
```

Since the ports of the containers were mapped to the host the various web ui's can be observed using a local browser.

**accumulomaster container**: AccumuloMaster Web UI on port 9995

AccumuloMaster: [http://localhost:9995/](http://localhost:9995/)

<img width="50%" alt="AccumuloMaster" src="https://user-images.githubusercontent.com/5332509/36404389-513946c2-15b8-11e8-9289-3c13647a536a.png">


**namenode container**: NameNode Web UI on port 50070

NameNode: [http://localhost:50070/dfshealth.html#tab-datanode](http://localhost:50070/dfshealth.html#tab-datanode)

<img width="50%" alt="NameNode" src="https://user-images.githubusercontent.com/5332509/36404476-d9f6194a-15b8-11e8-8926-5814c17b9993.png">

**resource manager container**: ResourceManager Web UI on ports 8088

ResourceManager: [http://localhost:8088/cluster](http://localhost:8088/cluster)

<img width="50%" alt="ResourceManager" src="https://user-images.githubusercontent.com/5332509/36404403-769dbd80-15b8-11e8-953b-6f1719e57c25.png">

**worker1 and worker2 containers**: DataNode Web UI on ports 50075 and 50076, NodeManager on 8042 and 8043

DataNode (worker1): [http://localhost:50075/datanode.html](http://localhost:50075/datanode.html)

<img width="50%" alt="Worker1 DataManager" src="https://user-images.githubusercontent.com/5332509/36404500-041ed932-15b9-11e8-8994-b51991f8106b.png">

NodeManager (worker1): [http://localhost:8042/node](http://localhost:8042/node)

<img width="50%" alt="NodeManager" src="https://user-images.githubusercontent.com/5332509/36404443-ad358472-15b8-11e8-8865-a2f1abdeea36.png">

DataNode (worker2): [http://localhost:50076/datanode.html](http://localhost:50076/datanode.html)

<img width="50%" alt="Worker2 DataManager" src="https://user-images.githubusercontent.com/5332509/36404524-25c017ea-15b9-11e8-9901-40319cde3750.png">

### Stop the cluster

The cluster can be stopped by issuing a `stop` call.

```
$ docker-compose stop
Stopping worker2         ... done
Stopping accumulomaster  ... done
Stopping worker1         ... done
Stopping resourcemanager ... done
Stopping namenode        ... done
Stopping zoo1            ... done
Stopping zoo2            ... done
```

### Restart the cluster

So long as the container definitions have not been removed, the cluster can be restarted by using a `start` call.

```
$ docker-compose start
Starting zoo1            ... done
Starting zoo2            ... done
Starting namenode        ... done
Starting worker2         ... done
Starting worker1         ... done
Starting resourcemanager ... done
Starting accumulomaster  ... done
```

After a few moments all cluster activity should be back to normal.

### Remove the cluster

The entire cluster can be removed by first stopping it, and then removing the containers from the local machine.

```
$ docker-compose stop && docker-compose rm -f
Stopping worker1         ... done
Stopping resourcemanager ... done
Stopping accumulomaster  ... done
Stopping worker2         ... done
Stopping namenode        ... done
Stopping zoo1            ... done
Stopping zoo2            ... done
Going to remove worker1, resourcemanager, accumulomaster, worker2, namenode, zoo1, zoo2
Removing worker1         ... done
Removing resourcemanager ... done
Removing accumulomaster  ... done
Removing worker2         ... done
Removing namenode        ... done
Removing zoo1            ... done
Removing zoo2            ... done
```

## Example: Accumulo command line

**NOTE**: Assumes the cluster is running as configured in the previous example.

A script named [usertable-example.sh](usertable-example.sh) will create a sample `usertable` in Accumulo using 100 randomly generated user entries. Calls to the `accumulomaster` container are made using `docker exec`.

The user can also invoke the accumulo shell with the following command.

```
$ docker exec -ti accumulomaster runuser -l hadoop -c '${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret'
```

Running usertable-example.sh:

```
$ ./usertable-example.sh
INFO: generate splits.txt
user2630
user6754
...
user1279
user2634
docker cp splits.txt accumulomaster:/tmp/splits.txt
INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "deletetable -f usertable"
2018-02-19 15:35:10,017 [trace.DistributedTrace] INFO : SpanReceiver org.apache.accumulo.tracer.ZooTraceClient was loaded successfully.
2018-02-19 15:35:10,211 [shell.Shell] ERROR: org.apache.accumulo.core.client.TableNotFoundException: Table usertable does not exist
INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "createtable usertable"
2018-02-19 15:35:13,920 [trace.DistributedTrace] INFO : SpanReceiver org.apache.accumulo.tracer.ZooTraceClient was loaded successfully.
INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "addsplits -t usertable -sf /tmp/splits.txt"
2018-02-19 15:35:17,697 [trace.DistributedTrace] INFO : SpanReceiver org.apache.accumulo.tracer.ZooTraceClient was loaded successfully.
INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "config -t usertable -s table.cache.block.enable=true"
2018-02-19 15:35:25,261 [trace.DistributedTrace] INFO : SpanReceiver org.apache.accumulo.tracer.ZooTraceClient was loaded successfully.
INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e tables
2018-02-19 15:35:28,434 [trace.DistributedTrace] INFO : SpanReceiver org.apache.accumulo.tracer.ZooTraceClient was loaded successfully.
accumulo.metadata
accumulo.replication
accumulo.root
trace
usertable
```

AccumuloMaster: [http://localhost:9995/master](http://localhost:9995/master)

<img width="50%" alt="AccumuloMaster usertable example" src="https://user-images.githubusercontent.com/5332509/36385949-336428fc-1562-11e8-96dd-6deedd76e2ab.png">

### References

1. ExoGENI Accumulo: [https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/accumulo/accumulo_exogeni_postboot.sh](https://github.com/RENCI-NRIG/exogeni-recipes/blob/master/accumulo/accumulo_exogeni_postboot.sh)
2. Accumulo Docs: [https://accumulo.apache.org/1.8/accumulo_user_manual.html](https://accumulo.apache.org/1.8/accumulo_user_manual.html)
3. Hadoop Docs: 
	- Common: [hadoop-common/core-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/core-default.xml)
	- HDFS: [hadoop-hdfs/hdfs-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)
	- MapReduce: [hadoop-mapreduce-client-core/mapred-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)
	- Yarn: [hadoop-yarn-common/yarn-default.xml](http://hadoop.apache.org/docs/r2.9.0/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)
	- Deprecated Properties: [hadoop-common/DeprecatedProperties.html](http://hadoop.apache.org/docs/r2.9.0/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
4. ZooKeeper Docs: [https://zookeeper.apache.org/doc/r3.4.11/zookeeperAdmin.html](https://zookeeper.apache.org/doc/r3.4.11/zookeeperAdmin.html)

