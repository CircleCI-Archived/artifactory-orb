This folder is used to configure a local RT pro docker image on localhost.


It is no longer used since we have hosted demo site at https://orbdemos.jfrog.io/orbdemo

The following commands can be added to config and calle dbfore and after any jfrog commands

```
# existing config
# ....

commands:
  setup-rt:
    description: Wait for Artifactory to intialize
    steps:
      - run:
          name: Initialize Artifactory Image
          command: |
            docker run --name artifactory -d -p 8081:8081 docker.bintray.io/jfrog/artifactory-pro:latest
            # wait for port availabiluty, otherwise curl errors out immediately
            while ! nc -z localhost 8081 ; do sleep 1 ; done
            #wait for artifactory to finish startup stuff
            STATUS="Dont know..."
            while [ "$STATUS" != "OK" ]; do
              echo "Waiting for Artifactory to initialize"
              sleep 2
              STATUS=`curl -uadmin:password  http://localhost:8081/artifactory/api/system/ping 2>/dev/null`
            done
            echo "Artifactory ready!"
            #setup our license
            echo '{"licenseKey":"'${RT_LICENSE_KEY}'"}' > license.json
            HTTPCODE=$(curl -s -o /dev/null -w "%{http_code}" \
              -uadmin:password -X POST -d @license.json -H "content-type:application/json" http://localhost:8081/artifactory/api/system/licenses) 
            if [ "$HTTPCODE" -ne 200 ];then
              echo "Unable to add license to Artifactory, failing build"
              curl -uadmin:password -X POST -d @license.json http://localhost:8081/artifactory/api/system/licenses
              exit 1
            fi
            echo "License configured"
            curl -uadmin:password http://localhost:8081/artifactory/api/system/licenses
            #setup docker repo...
            curl -X PUT -d @docker-repo.json -H "content-type: application/json" -u admin:password http://localhost:8081/artifactory/api/repositories/docker-repo
            # setup http settings for pth ccess to docker repo
            curl -uadmin:password -X POST -d @webServer.json -H "content-type:application/json" http://localhost:8081/artifactory/api/system/configuration/webServer

      - run: |
          echo "export ARTIFACTORY_URL=http://localhost:8081/artifactory" >> $BASH_ENV
          echo "export ARTIFACTORY_USER=admin" >> $BASH_ENV
      - run: |
          ARTIFACTORY_API_KEY=$(curl -uadmin:password -X POST http://localhost:8081/artifactory/api/security/apiKey | jq -r '.apiKey')
          echo "export ARTIFACTORY_API_KEY=${ARTIFACTORY_API_KEY}" >> $BASH_ENV
          echo "Created API KEy: ${ARTIFACTORY_API_KEY}"
      - run: curl -uadmin:password  http://localhost:8081/artifactory/api/system
  inspect-rt:
    description: Confirm existience of our assets in Artifactory
    steps:
      - run: curl http://localhost:8081/artifactory/api/builds | jq
      - run: curl http://localhost:8081/artifactory/api/storage/docker-repo | jq
```