pipeline {
    agent any

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
                    docker build \
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
                    for i in {1..10}; do
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

        stage('Push image to staging and deploy') {
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    sh """
                        echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com
                        docker tag alphabalde/${IMAGE_NAME}:${IMAGE_TAG} registry.heroku.com/${STAGING}/web
                        docker push registry.heroku.com/${STAGING}/web
                        heroku container:release web -a ${STAGING}
                    """
                }
            }
        }

stage('Push image to prod and deploy') {
    when {
        expression { env.GIT_BRANCH == 'origin/master' }
    }
    steps {
        withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
            sh """
                # Login to Heroku registry
                echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com

                # Push image to Heroku prod app
                heroku container:push web -a ${PRODUCTION}

                # Release the pushed image
                heroku container:release web -a ${PRODUCTION}
            """
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
