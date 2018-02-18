#!/usr/bin/env bash

echo "INFO: generate splits.txt"
> splits.txt
for run in {1..100}
do
  echo 'user'$((1000 + RANDOM % 8999)) >> splits.txt
done
cat splits.txt

echo "docker cp splits.txt accumulomaster:/tmp/splits.txt"
docker cp splits.txt accumulomaster:/tmp/splits.txt

echo 'INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "deletetable -f usertable"'
docker exec -ti accumulomaster runuser -l hadoop -c '${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "deletetable -f usertable"'

echo 'INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "createtable usertable"'
docker exec -ti accumulomaster runuser -l hadoop -c '${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "createtable usertable"'

# addsplits -t usertable -sf /tmp/splits.txt
echo 'INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "addsplits -t usertable -sf /tmp/splits.txt"'
docker exec -ti accumulomaster runuser -l hadoop -c '${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "addsplits -t usertable -sf /tmp/splits.txt"'

# config -t usertable -s table.cache.block.enable=true
echo 'INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "config -t usertable -s table.cache.block.enable=true"'
docker exec -ti accumulomaster runuser -l hadoop -c '${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e "config -t usertable -s table.cache.block.enable=true"'

echo 'INFO: ${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e tables'
docker exec -ti accumulomaster runuser -l hadoop -c '${ACCUMULO_HOME}/bin/accumulo shell -u root -p secret -e tables'

exit 0;
