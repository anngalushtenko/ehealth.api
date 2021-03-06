pipeline {
  agent none
  stages {
    stage('Test') {
      environment {
        MIX_ENV = 'test'
        DOCKER_NAMESPACE = 'edenlabllc'
        POSTGRES_VERSION = '9.6'
        POSTGRES_USER = 'postgres'
        POSTGRES_PASSWORD = 'postgres'
        POSTGRES_DB = 'postgres'
      }
      agent {
        kubernetes {
          label 'ehealth-test'
          defaultContainer 'jnlp'
          yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: test
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: elixir
    image: elixir:1.8.1-alpine
    command:
    - cat
    tty: true
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  - name: mongo
    image: mvertes/alpine-mongo:4.0.1-0
    ports:
    - containerPort: 27017
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "184Mi"
        cpu: "100m"
  - name: redis
    image: redis:4-alpine3.9
    ports:
    - containerPort: 6379
    tty: true
  nodeSelector:
    node: ci
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'elixir', shell: '/bin/sh') {
              sh '''
                apk update && apk add --no-cache jq curl bash git ncurses-libs zlib ca-certificates openssl;
                sed -i "s|localhost|kafka.kafka.svc.cluster.local|g" apps/core/config/config.exs
                mix local.hex --force;
                mix local.rebar --force;
                mix deps.get;
                mix deps.compile;
                curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/tests.sh -o tests.sh; bash ./tests.sh
              '''
            }
          }
        }
    stage('Test and build') {
      environment {
        MIX_ENV = 'test'
        DOCKER_NAMESPACE = 'edenlabllc'
        POSTGRES_VERSION = '9.6'
        POSTGRES_USER = 'postgres'
        POSTGRES_PASSWORD = 'postgres'
        POSTGRES_DB = 'postgres'
      }
      parallel {
        stage('Build ehealth') {
          environment {
            APPS='[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label 'ehealth-build'
              defaultContainer 'jnlp'
              yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: lakone/docker:18.09-alpine3.9
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: volume
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "384Mi"
        cpu: "500m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  nodeSelector:
    node: ci
  volumes:
  - name: volume
    hostPath:
      path: /var/run/docker.sock
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for EHealth API-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s|REDIS_URI=redis://travis:6379|REDIS_URI=redis://redis-master.redis.svc.cluster.local:6379|g" .env'
              sh 'sed -i "s|MONGO_DB_URL=mongodb://travis:27017/taskafka|MONGO_DB_URL=mongodb://me-db-mongodb-replicaset.me-db.svc.cluster.local:27017/taskafka?replicaSet=rs0&readPreference=primary|g" .env'
              sh 'sed -i "s/KAFKA_BROKERS_HOST=travis/KAFKA_BROKERS_HOST=kafka.kafka.svc.cluster.local/g" .env'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          post {
            always {
              container(name: 'docker', shell: '/bin/sh') {
                sh 'echo " ---- step: Remove docker image from host ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
              }
            }
          }
        }
        stage('Build casher') {
          environment {
            APPS='[{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label 'casher-build'
              defaultContainer 'jnlp'
              yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: lakone/docker:18.09-alpine3.9
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: volume
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "384Mi"
        cpu: "500m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  nodeSelector:
    node: ci
  volumes:
  - name: volume
    hostPath:
      path: /var/run/docker.sock
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for Casher-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s|REDIS_URI=redis://travis:6379|REDIS_URI=redis://redis-master.redis.svc.cluster.local:6379|g" .env'
              sh 'sed -i "s|MONGO_DB_URL=mongodb://travis:27017/taskafka|MONGO_DB_URL=mongodb://me-db-mongodb-replicaset.me-db.svc.cluster.local:27017/taskafka?replicaSet=rs0&readPreference=primary|g" .env'
              sh 'sed -i "s/KAFKA_BROKERS_HOST=travis/KAFKA_BROKERS_HOST=kafka.kafka.svc.cluster.local/g" .env'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          post {
            always {
              container(name: 'docker', shell: '/bin/sh') {
                sh 'echo " ---- step: Remove docker image from host ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
              }
            }
          }
        }
        stage('Build graphql') {
          environment {
            APPS='[{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label 'graphql-build'
              defaultContainer 'jnlp'
              yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: lakone/docker:18.09-alpine3.9
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: volume
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "384Mi"
        cpu: "500m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  nodeSelector:
    node: ci
  volumes:
  - name: volume
    hostPath:
      path: /var/run/docker.sock
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for GraphQL-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s|REDIS_URI=redis://travis:6379|REDIS_URI=redis://redis-master.redis.svc.cluster.local:6379|g" .env'
              sh 'sed -i "s|MONGO_DB_URL=mongodb://travis:27017/taskafka|MONGO_DB_URL=mongodb://me-db-mongodb-replicaset.me-db.svc.cluster.local:27017/taskafka?replicaSet=rs0&readPreference=primary|g" .env'
              sh 'sed -i "s/KAFKA_BROKERS_HOST=travis/KAFKA_BROKERS_HOST=kafka.kafka.svc.cluster.local/g" .env'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          post {
            always {
              container(name: 'docker', shell: '/bin/sh') {
                sh 'echo " ---- step: Remove docker image from host ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
              }
            }
          }
        }
        stage('Build merge-legal-entities-consumer') {
          environment {
            APPS='[{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label 'merge-legal-entities-consumer-build'
              defaultContainer 'jnlp'
              yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: lakone/docker:18.09-alpine3.9
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: volume
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "384Mi"
        cpu: "500m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  nodeSelector:
    node: ci
  volumes:
  - name: volume
    hostPath:
      path: /var/run/docker.sock
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for MergeLegalEntities consumer-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s|REDIS_URI=redis://travis:6379|REDIS_URI=redis://redis-master.redis.svc.cluster.local:6379|g" .env'
              sh 'sed -i "s|MONGO_DB_URL=mongodb://travis:27017/taskafka|MONGO_DB_URL=mongodb://me-db-mongodb-replicaset.me-db.svc.cluster.local:27017/taskafka?replicaSet=rs0&readPreference=primary|g" .env'
              sh 'sed -i "s/KAFKA_BROKERS_HOST=travis/KAFKA_BROKERS_HOST=kafka.kafka.svc.cluster.local/g" .env'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          post {
            always {
              container(name: 'docker', shell: '/bin/sh') {
                sh 'echo " ---- step: Remove docker image from host ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
              }
            }
          }
        }
        stage('Build deactivate-legal-entity-consumer') {
          environment {
            APPS='[{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label 'deactivate-legal-entity-consumer-build'
              defaultContainer 'jnlp'
              yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: lakone/docker:18.09-alpine3.9
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: volume
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "384Mi"
        cpu: "500m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  nodeSelector:
    node: ci
  volumes:
  - name: volume
    hostPath:
      path: /var/run/docker.sock
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for DeactivateLegalEntities consumer-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s|REDIS_URI=redis://travis:6379|REDIS_URI=redis://redis-master.redis.svc.cluster.local:6379|g" .env'
              sh 'sed -i "s|MONGO_DB_URL=mongodb://travis:27017/taskafka|MONGO_DB_URL=mongodb://me-db-mongodb-replicaset.me-db.svc.cluster.local:27017/taskafka?replicaSet=rs0&readPreference=primary|g" .env'
              sh 'sed -i "s/KAFKA_BROKERS_HOST=travis/KAFKA_BROKERS_HOST=kafka.kafka.svc.cluster.local/g" .env'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          post {
            always {
              container(name: 'docker', shell: '/bin/sh') {
                sh 'echo " ---- step: Remove docker image from host ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
              }
            }
          }
        }
        stage('Build ehealth-scheduler') {
          environment {
            APPS='[{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
            DOCKER_CREDENTIALS = 'credentials("20c2924a-6114-46dc-8e39-bfadd1cf8acf")'
            POSTGRES_USER = 'postgres'
            POSTGRES_PASSWORD = 'postgres'
            POSTGRES_DB = 'postgres'
          }
          agent {
            kubernetes {
              label 'ehealth-scheduler-build'
              defaultContainer 'jnlp'
              yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: build
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: docker
    image: lakone/docker:18.09-alpine3.9
    volumeMounts:
    - mountPath: /var/run/docker.sock
      name: volume
    env:
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "384Mi"
        cpu: "500m"
  - name: postgres
    image: edenlabllc/alpine-postgre:pglogical-gis-1.1
    ports:
    - containerPort: 5432
    tty: true
  nodeSelector:
    node: ci
  volumes:
  - name: volume
    hostPath:
      path: /var/run/docker.sock
'''
            }
          }
          steps {
            container(name: 'postgres', shell: '/bin/sh') {
              sh '''
              sleep 15;
              psql -U postgres -c "create database ehealth";
              psql -U postgres -c "create database prm_dev";
              psql -U postgres -c "create database fraud_dev";
              psql -U postgres -c "create database event_manager_dev";
              '''
            }
            container(name: 'docker', shell: '/bin/sh') {
              sh 'echo -----Build Docker container for Scheduler-------'
              sh 'apk update && apk add --no-cache jq curl bash elixir git ncurses-libs zlib ca-certificates openssl erlang-crypto erlang-runtime-tools;'
              sh 'echo " ---- step: Build docker image ---- ";'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/build-container.sh -o build-container.sh; bash ./build-container.sh'
              sh 'echo " ---- step: Start docker container ---- ";'
              sh 'mix local.rebar --force'
              sh 'mix local.hex --force'
              sh 'mix deps.get'
              sh 'sed -i "s|REDIS_URI=redis://travis:6379|REDIS_URI=redis://redis-master.redis.svc.cluster.local:6379|g" .env'
              sh 'sed -i "s|MONGO_DB_URL=mongodb://travis:27017/taskafka|MONGO_DB_URL=mongodb://me-db-mongodb-replicaset.me-db.svc.cluster.local:27017/taskafka?replicaSet=rs0&readPreference=primary|g" .env'
              sh 'sed -i "s/KAFKA_BROKERS_HOST=travis/KAFKA_BROKERS_HOST=kafka.kafka.svc.cluster.local/g" .env'
              sh 'sed -i "s/travis/${POD_IP}/g" .env'
              sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/start-container.sh -o start-container.sh; bash ./start-container.sh'
              withCredentials(bindings: [usernamePassword(credentialsId: '8232c368-d5f5-4062-b1e0-20ec13b0d47b', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                sh 'echo " ---- step: Push docker image ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/push-changes.sh -o push-changes.sh; bash ./push-changes.sh'
              }
            }
          }
          post {
            always {
              container(name: 'docker', shell: '/bin/sh') {
                sh 'echo " ---- step: Remove docker image from host ---- ";'
                sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/remove-containers.sh -o remove-containers.sh; bash ./remove-containers.sh'
              }
            }
          }
        }
      }
    }
    stage ('Deploy') {
      when {
        branch 'develop'
      }
      environment {
        APPS = '[{"app":"ehealth","chart":"il","namespace":"il","deployment":"api","label":"api"},{"app":"casher","chart":"il","namespace":"il","deployment":"casher","label":"casher"},{"app":"graphql","chart":"il","namespace":"il","deployment":"graphql","label":"graphql"},{"app":"merge_legal_entities_consumer","chart":"il","namespace":"il","deployment":"merge-legal-entities-consumer","label":"merge-legal-entities-consumer"},{"app":"deactivate_legal_entity_consumer","chart":"il","namespace":"il","deployment":"deactivate-legal-entity-consumer","label":"deactivate-legal-entity-consumer"},{"app":"ehealth_scheduler","chart":"il","namespace":"il","deployment":"ehealth-scheduler","label":"ehealth-scheduler"}]'
      }
      agent {
        kubernetes {
          label 'Ehealth-deploy'
          defaultContainer 'jnlp'
          yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    stage: deploy
spec:
  tolerations:
  - key: "node"
    operator: "Equal"
    value: "ci"
    effect: "NoSchedule"
  containers:
  - name: kubectl
    image: lachlanevenson/k8s-kubectl:v1.13.2
    command:
    - cat
    tty: true
  nodeSelector:
    node: ci
'''
        }
      }
      steps {
        container(name: 'kubectl', shell: '/bin/sh') {
          sh 'apk add curl bash jq'
          sh 'echo " ---- step: Deploy to cluster ---- ";'
          sh 'curl -s https://raw.githubusercontent.com/edenlabllc/ci-utils/umbrella_jenkins/autodeploy.sh -o autodeploy.sh; bash ./autodeploy.sh'
        }
      }
    }
  }
  post { 
    success {
      slackSend (color: 'good', message: "SUCCESSFUL: Job - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) success in ${currentBuild.durationString}")
    }
    failure {
      slackSend (color: 'danger', message: "FAILED: Job - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) failed in ${currentBuild.durationString}")
    }
    aborted {
      slackSend (color: 'warning', message: "ABORTED: Job - ${env.JOB_NAME} ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>) canceled in ${currentBuild.durationString}")
    }
  }
}