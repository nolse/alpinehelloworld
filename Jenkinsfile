pipeline {
    agent any   // ✅ Un seul agent pour tout le pipeline

    environment {
        IMAGE_NAME     = "alpinehelloworld"
        IMAGE_TAG      = "latest"
        CONTAINER_NAME = "${IMAGE_NAME}-${BUILD_NUMBER}"
        STAGING        = "eazytraining-staging-alpha"
        PRODUCTION     = "eazytraining-prod-alpha"
    }

    stages {

        stage('Build image') {
            steps {
                sh """
                    docker rmi alphabalde/${IMAGE_NAME}:${IMAGE_TAG} || true
                    export DOCKER_BUILDKIT=0
                    docker build \
                        --no-cache \
                        --platform linux/amd64 \
                        -t alphabalde/${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Run container') {
            steps {
                sh """
                    docker rm -f ${CONTAINER_NAME} || true
                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p 5000:5000 \
                        -e PORT=5000 \
                        alphabalde/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Test image') {
            steps {
                sh """
                    echo "Attente du démarrage de l'application..."
                    for i in 1 2 3 4 5 6 7 8 9 10; do
                        if docker exec ${CONTAINER_NAME} curl -s http://localhost:5000 | grep -iq "hello world"; then
                            echo "Application OK"
                            exit 0
                        fi
                        sleep 3
                    done
                    echo "Application non disponible"
                    docker logs ${CONTAINER_NAME}
                    exit 1
                """
            }
        }

        stage('Clean container') {
            steps {
                sh "docker rm -f ${CONTAINER_NAME} || true"
            }
        }

        stage('Push image in staging and deploy') {
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    withEnv(["DOCKER_BUILDKIT=0", "COMPOSE_DOCKER_CLI_BUILD=0"]) {
                        sh '''
                            echo $HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com
                            docker tag alphabalde/alpinehelloworld:latest registry.heroku.com/eazytraining-staging-alpha/web
                            docker push registry.heroku.com/eazytraining-staging-alpha/web
                            /usr/bin/heroku container:release web -a eazytraining-staging-alpha
                        '''
                    }
                }
            }
        }

        stage('Push image in prod and deploy') {
            when {
                expression { env.GIT_BRANCH == 'origin/master' }
            }
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    withEnv(["DOCKER_BUILDKIT=0", "COMPOSE_DOCKER_CLI_BUILD=0"]) {
                        sh """
                            echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com

                            # Supprimer l'ancienne image prod pour éviter les conflits
                            docker rmi registry.heroku.com/${PRODUCTION}/web || true

                            # Tag de l'image locale pour prod
                            docker tag alphabalde/${IMAGE_NAME}:${IMAGE_TAG} registry.heroku.com/${PRODUCTION}/web

                            # Push sur le registry Heroku
                            docker push registry.heroku.com/${PRODUCTION}/web

                            # Release sur Heroku
                            heroku container:release web -a ${PRODUCTION}
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sh "docker rm -f ${CONTAINER_NAME} || true"
        }
    }
}
