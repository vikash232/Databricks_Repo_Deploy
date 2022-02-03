python --version

#https://docs.databricks.com/dev-tools/databricks-connect.html#step-2-configure-connection-properties
#$ORGANIZATIONID id is one after ?o in https://abc-xyz.cloud.databricks.com/?o=828088473111111
echo "Y
      $DBURL
      $TOKEN
      $CLUSTERID
      $ORGANIZATIONID
      15001" | databricks-connect configure