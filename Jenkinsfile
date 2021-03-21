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
    HAB_AUTH_TOKEN = credentials("hab-token")
    HAB_BLDR_URL = credentials("hab-builder-url")
  }

  stages {
    stage("ensure config") {
      steps {
        sh '''
          mkdir -p /hab/cache/keys
          cp -u $HAB_KEY_FILE /hab/cache/keys
        '''
      }
    }

    stage("publish release") {
      when {
        branch "main"
      }
      steps {
        sh '''
          for i in {1..`cat release.json|jq 'length'`}; do
            key=`cat release.json|jq -r 'keys['$i' - 1]'`
            value=`cat release.json|jq -r '.'$key`
            echo $key "-" $value
            hab 
          done
        '''
      }
    }

    stage("publish artifact") {
      when {
        expression { env.BRANCH_NAME != null && env.BRANCH_NAME.matches("^v\\d+\\.\\d+.*") }
      }
      steps {
        sh '''
          release_ver=`cat release.json|jq -r ".latest"`
          sed "s|pkg_version=.*|pkg_version=$release_ver|g" -i habitat/plan.sh
          hab pkg build pozoledf-sample-app -k $HAB_ORIGIN
          hab pkg upload --force -c dev results/*.hart
        '''
      }
    }
  }
}