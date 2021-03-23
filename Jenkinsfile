pipeline {
  agent {
    docker {
      image "kuritsu/pozoledf-jenkins-util:latest"
      args "--entrypoint='' --network host -u root --privileged -v /var/run/docker.sock:/var/run/docker.sock"
    }
  }

  environment {
    DOCKER_REGISTRY = credentials("docker-registry-fqdn")
    HAB_ORIGIN = credentials("hab-origin")
    HAB_KEY_FILE = credentials("hab-origin-private-key-file")
    HAB_PUB_FILE = credentials("hab-origin-public-key-file")
    HAB_AUTH_TOKEN = credentials("hab-token")
    HAB_BLDR_URL = credentials("hab-builder-url")
    HAB_BLDR_CERT_FILE = credentials("hab-builder-certificate")
    HAB_LICENSE = "accept"
  }

  stages {
    stage("ensure config") {
      steps {
        sh '''
          mkdir -p /hab/cache/keys
          cp -u $HAB_KEY_FILE /hab/cache/keys
          cp -u $HAB_PUB_FILE /hab/cache/keys
          mkdir -p /hab/cache/ssl
          cp -u $HAB_BLDR_CERT_FILE /hab/cache/ssl
        '''
      }
    }

    stage("promote release") {
      when {
        branch "main"
      }
      steps {
        sh '''
          #!/bin/bash
          length=`cat release.json|jq 'length'`
          i=0
          while [ $i -lt $length ]; do
            key=`cat release.json|jq -r 'keys['$i']'`
            i=$((i + 1))
            if [ "$key" = "dev" ]; then
              continue
            fi
            value=`cat release.json|jq -r '.'$key`
            echo $key "-" $value
            mkdir -p $key
            hab pkg download ${HAB_ORIGIN}/pozoledf-sample-app/$value -c dev --download-directory $key
            if [ $? = 0 ]; then
              pkg_release=`hab pkg info $key/artifacts/*.hart|tail -n 1|awk 'BEGIN { FS = " : " } ; { print $2 }'`
              hab pkg promote ${HAB_ORIGIN}/pozoledf-sample-app/$value/$pkg_release $key
            fi
          done
        '''
      }
    }

    stage("publish release") {
      when {
        expression { env.BRANCH_NAME != null && env.BRANCH_NAME.matches("^v\\d+\\.\\d+.*") }
      }
      steps {
        sh '''
          release_ver=`cat release.json|jq -r ".dev"`
          sed "s|pkg_version=.*|pkg_version=$release_ver|g" -i habitat/plan.sh
          export HAB_BLDR_URL2=$HAB_BLDR_URL
          unset HAB_BLDR_URL # so we can build successfully
          hab pkg build . -k $HAB_ORIGIN
          export HAB_BLDR_URL=$HAB_BLDR_URL2
          hab pkg upload --force -c dev results/*.hart
        '''
      }
    }
  }
}