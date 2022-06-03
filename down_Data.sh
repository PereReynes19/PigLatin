#! /bin/sh

# Descarreguem el fitxer passat per paràmetres i canviem el nom
wget $1 -O bike_rental.zip

# Descomprimim el zip
unzip -c bike_rental.zip > bike_rental.csv

# Pujem el csv a l'hdfs
hdfs dfs -put bike_rental.csv /user/cloudera/WorkspaceOoziePractica
