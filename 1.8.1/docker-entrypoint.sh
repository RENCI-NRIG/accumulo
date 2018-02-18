#!/usr/bin/env bash
set -e

# location of hadoop configuration files
HADOOP_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop
ACCUMULO_CONF_DIR=${ACCUMULO_HOME}/conf
CORE_SITE_FILE=${HADOOP_CONF_DIR}/core-site.xml
HDFS_SITE_FILE=${HADOOP_CONF_DIR}/hdfs-site.xml
MAPRED_SITE_FILE=${HADOOP_CONF_DIR}/mapred-site.xml
YARN_SITE_FILE=${HADOOP_CONF_DIR}/yarn-site.xml
WORKERS_FILE=${HADOOP_CONF_DIR}/slaves
ACCUMULO_SITE_FILE=${ACCUMULO_CONF_DIR}/accumulo-site.xml

# generate or use provided core-site.xml
_core_site_xml () {
  if [ -f /site-files/core-site.xml ]; then
    echo "USE: /site-files/core-site.xml"
    cat /site-files/core-site.xml > $CORE_SITE_FILE
  else
    cat > $CORE_SITE_FILE << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $CORE_SITE_FILE
}

# generate or use provided hdfs-site.xml
_hdfs_site_xml () {
  if [ -f /site-files/hdfs-site.xml ]; then
    cat /site-files/hdfs-site.xml > $HDFS_SITE_FILE
  else
    cat > $HDFS_SITE_FILE << EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.name.dir</name>
    <value>file:///hdfsdata/namenode</value>
  </property>
  <property>
    <name>dfs.data.dir</name>
    <value>file:///hdfsdata/datanode</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $HDFS_SITE_FILE
}

# generate or use provided mapred-site.xml
_mapred_site_xml() {
  if [ -f /site-files/mapred-site.xml ]; then
    cat /site-files/mapred-site.xml > $MAPRED_SITE_FILE
  else
    cat > $MAPRED_SITE_FILE << EOF
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!-- Put site-specific property overrides in this file. -->
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $MAPRED_SITE_FILE
}

# generate or use provided yarn-site.xml
_yarn_site_xml() {
  if [ -f /site-files/yarn-site.xml ]; then
    cat /site-files/yarn-site.xml > $YARN_SITE_FILE
  else
    cat > $YARN_SITE_FILE << EOF
<?xml version="1.0"?>
<!-- Site specific YARN configuration properties -->
<configuration>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
</configuration>
EOF
  fi
  chown hadoop:hadoop $YARN_SITE_FILE
}

# generate or use provided workers (slaves)
_workers() {
  if [ -f /site-files/workers ]; then
    cat /site-files/workers > $WORKERS_FILE
  else
    cat > $WORKERS_FILE << EOF
localhost
EOF
  fi
  chown hadoop:hadoop $WORKERS_FILE
}

# set /etc/profile.d/hadoop.sh
_hadoop_profile() {
  cat > /etc/profile.d/hadoop.sh << EOF
export HADOOP_USER_HOME=${HADOOP_USER_HOME}
export HADOOP_HOME=${HADOOP_USER_HOME}/hadoop
export HADOOP_PREFIX=${HADOOP_USER_HOME}/hadoop
export HADOOP_INSTALL=${HADOOP_PREFIX}
export HADOOP_MAPRED_HOME=${HADOOP_PREFIX}
export HADOOP_COMMON_HOME=${HADOOP_PREFIX}
export HADOOP_HDFS_HOME=${HADOOP_PREFIX}
export JAVA_LIBRARY_PATH=${JAVA_LIBRARY_PATH}:${HADOOP_PREFIX}/lib/native
export YARN_HOME=${HADOOP_PREFIX}
export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_PREFIX}/lib/native
export HADOOP_CONF_DIR=${HADOOP_PREFIX}/etc/hadoop
export CORE_SITE_FILE=${HADOOP_CONF_DIR}/core-site.xml
export HDFS_SITE_FILE=${HADOOP_CONF_DIR}/hdfs-site.xml
export MAPRED_SITE_FILE=${HADOOP_CONF_DIR}/mapred-site.xml
export YARN_SITE_FILE=${HADOOP_CONF_DIR}/yarn-site.xml
export WORKERS_FILE=${HADOOP_CONF_DIR}/slaves
export PATH=$PATH:${HADOOP_PREFIX}/sbin:${HADOOP_PREFIX}/bin
EOF
}

# generate ssh kesy for hadoop user
_generate_ssh_keys() {
  mkdir -p $HADOOP_USER_HOME/.ssh
  ssh-keygen -t rsa -N '' -f $HADOOP_USER_HOME/.ssh/id_rsa
  cat $HADOOP_USER_HOME/.ssh/id_rsa.pub >> $HADOOP_USER_HOME/.ssh/authorized_keys
  chmod 0600 $HADOOP_USER_HOME/.ssh/authorized_keys
  chown -R hadoop:hadoop $HADOOP_USER_HOME/.ssh
}

# set /etc/profile.d/accumulo.sh
_accumulo_profile() {
  cat > /etc/profile.d/accumulo.sh << EOF
export ACCUMULO_VERSION=${ACCUMULO_VERSION}
export ACCUMULO_PASSWORD=${ACCUMULO_PASSWORD}
export ACCUMULO_INSTANCE=${ACCUMULO_INSTANCE}
export ACCUMULO_HOME=${ACCUMULO_HOME}
export ZOOKEEPER_HOME=/home/hadoop/zookeeper
export ZOOKEEPER_NODES=${ZOOKEEPER_NODES}
EOF
}

_accumulo_site_xml() {
  if [ -f /site-files/accumulo-site.xml ]; then
    cat /site-files/accumulo-site.xml > $ACCUMULO_SITE_FILE
  else
    # setup zookeeper hosts
    for node in `echo $ZOOKEEPER_NODES`; do ZK_HOSTS=$ZK_HOSTS$node:2181,; done
    sed -i "/localhost:2181/ s/localhost:2181/${ZK_HOSTS%?}/" ${ACCUMULO_HOME}/conf/accumulo-site.xml

    # disable SASL (?) Kerberos ??
    # this is disabled correctly by bootstrap_config.sh
    #sed -i '/instance.rpc.sasl.enabled/!b;n;s/true/false/' ${ACCUMULO_HOME}/conf/accumulo-site.xml
    # if the password is changed by the user, the script needs to change it here too.
    sed -i "/<value>secret/s/secret/${ACCUMULO_PASSWORD}/" ${ACCUMULO_HOME}/conf/accumulo-site.xml

    sed -i '/<name>instance.volumes<\/name>/!b;n;c\ \ \ \ <value>hdfs:\/\/namenode:9000\/accumulo<\/value>' ${ACCUMULO_HOME}/conf/accumulo-site.xml
  fi
  chown hadoop:hadoop $ACCUMULO_SITE_FILE
}

# set profile and check env for hadoop user
_hadoop_profile
_accumulo_profile
# runuser -l hadoop -c $'env' # debug hadoop env

if $IS_NAME_NODE; then
  mkdir -p /hdfsdata/namenode
  chown -R hadoop:hadoop /hdfsdata/namenode
fi
if $IS_DATA_NODE; then
  mkdir -p /hdfsdata/datanode
  chown -R hadoop:hadoop /hdfsdata/datanode
fi

# set ownership of directory used to transfer ssh settings between nodes
chown -R hadoop:hadoop /home/hadoop/public

# start sshd daemon
/usr/sbin/sshd -D &

# update JAVA_HOME in hadoop-env
runuser -l hadoop -c $'sed -i \'s:export JAVA_HOME=.*:export JAVA_HOME=/usr/java/jdk1.8.0_161/jre:\' /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh'

# set haddop configuration files
_core_site_xml
_hdfs_site_xml
_mapred_site_xml
_yarn_site_xml
_workers

# determine if this is the first time the cluster has been run
IS_FIRST_RUN=$(if [ ! -f "/home/hadoop/.ssh/id_rsa.pub" ]; then echo 'true'; else echo 'false'; fi)

# NameNode to set the ssh keys used by all containers
if $IS_NAME_NODE; then
  if $IS_FIRST_RUN; then
  echo "NameNode copy ssh"
    _generate_ssh_keys
    cp -r /home/hadoop/.ssh /home/hadoop/public/
  fi
else
  while [ ! -d /home/hadoop/public/.ssh ]; do
    echo "waiting for /home/hadoop/public/.ssh"
    sleep 2
  done
  if $IS_FIRST_RUN; then
    echo "COPY: .ssh from namenode to $(hostname)"
    cp -rf /home/hadoop/public/.ssh /home/hadoop/
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
    chown -R hadoop:hadoop /home/hadoop/.ssh
  fi
fi

# Register all other cluster nodes in known_hosts
if $IS_FIRST_RUN; then
  while read node; do
    echo "node = $node"
    until runuser -l hadoop -c $'ssh-keyscan $node >> /home/hadoop/.ssh/known_hosts'; do sleep 2; done
  done < <($CLUSTER_NODES)
fi

# NameNode startup commands
if $IS_NAME_NODE; then
    echo "Staring NameNode"
    if $IS_FIRST_RUN; then
      runuser -l hadoop -c $'$HADOOP_PREFIX/bin/hdfs namenode -format'
    fi
    runuser -l hadoop -c $'$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode'
fi

# SecondaryNameNode startup commands
if $IS_SECONDARY_NAME_NODE; then
    echo "Staring SecondaryNameNode"
    runuser -l hadoop -c $'$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start secondarynamenode'
fi

# DataNode startup commands
if $IS_DATA_NODE; then
    echo "Staring DataNode"
    runuser -l hadoop -c $'$HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode'
fi

# ResourceManager startup commands
if $IS_RESOURCE_MANAGER; then
    echo "Staring ResourceManager"
    runuser -l hadoop -c $'$YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager'
fi

# NodeManager startup commands
if $IS_NODE_MANAGER; then
    echo "Staring NodeManager"
    runuser -l hadoop -c $'$YARN_HOME/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start nodemanager'
fi

# Accumulo configuration
if $IS_FIRST_RUN; then
  # bootstrap node
  runuser -l hadoop -c $'cd ${ACCUMULO_HOME}; ${ACCUMULO_HOME}/bin/bootstrap_config.sh --size 1GB --jvm --version 2;'

  # define Accumulo node roles
  sed -i "/localhost/ s/.*/$ACCUMULO_MASTER/" ${ACCUMULO_HOME}/conf/masters
  sed -i "/localhost/ s/.*/$ACCUMULO_MASTER/" ${ACCUMULO_HOME}/conf/monitor
  sed -i "/localhost/ s/.*/$ACCUMULO_MASTER/" ${ACCUMULO_HOME}/conf/gc
  sed -i "/localhost/ s/.*/$ACCUMULO_MASTER/" ${ACCUMULO_HOME}/conf/tracers

  # set Accumulo workers
  > ${ACCUMULO_HOME}/conf/slaves
  for node in `echo $ACCUMULO_WORKERS`; do
    echo $node >> ${ACCUMULO_HOME}/conf/slaves
  done

  _accumulo_site_xml

  # Need monitor to bind to public port
  sed -i "/ACCUMULO_MONITOR_BIND_ALL/ s/^# //" ${ACCUMULO_HOME}/conf/accumulo-env.sh
fi

if $IS_ACCUMULO_MASTER; then
  if $IS_FIRST_RUN; then
    # install nc for zookeeper status calls
    yum install -y nc
  fi
  # ensure zookeeper nodes are up and ready
  for node in `echo $ZOOKEEPER_NODES`; do
    zoo_resp=''
    while [ "$zoo_resp" != 'imok' ]; do
      zoo_resp=$(echo ruok | nc $node 2181)
      sleep 2s
    done
    ZK_HOSTS=$ZK_HOSTS$node:2181,;
  done
  # initialize the Accumulo cluster
  if $IS_FIRST_RUN; then
    # runuser -l hadoop -c $'${ACCUMULO_HOME}/bin/accumulo init --instance-name exogeni --password ${ACCUMULO_PASSWORD} --user root'
    runuser -l hadoop -c $'${ACCUMULO_HOME}/bin/accumulo init --clear-instance-name <<EOF
${ACCUMULO_INSTANCE}
${ACCUMULO_PASSWORD}
${ACCUMULO_PASSWORD}
EOF'
  fi
  # start the AccumuloMaster node
  runuser -l hadoop -c $'${ACCUMULO_HOME}/bin/start-here.sh'
fi

# start the Accumulo Woker (tserver) nodes
if $IS_ACCUMULO_WORKER; then
  until runuser -l hadoop -c $'${HADOOP_PREFIX}/bin/hdfs dfs -ls /accumulo/instance_id > /dev/null 2>&1'
  do
    sleep 1
  done
  runuser -l hadoop -c $'${ACCUMULO_HOME}/bin/start-here.sh'
fi

# keep process busy so that container doesn't exit
tail -f /dev/null

exec "$@"
