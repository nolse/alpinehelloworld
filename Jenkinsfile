pipeline { // AUTOMATISATION

    agent none

    environment {
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG  = "latest"
        STAGING    = "eazytraining-staging-alpha"
        PRODUCTION = "eazytraining-prod-alpha"
    }

    stages {

        stage('Build image') {
            agent any
            steps {
                sh '''
                    docker build -t alphabalde/${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Run container based on builded image') {
            agent any
            steps {
                sh '''
                    docker run --name $IMAGE_NAME -d \
                      -p 80:5000 \
                      -e PORT=5000 \
                      alphabalde/${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 5
                '''
            }
        }

        stage('Test image') {
            agent any
            steps {
                sh '''
                    curl http://172.17.0.1:80 | grep -iq "hello world!"
                '''
            }
        }

        stage('Clean container') {
            agent any
            steps {
                sh '''
                    docker stop $IMAGE_NAME || true
                    docker rm $IMAGE_NAME || true
                '''
            }
        }

        stage('Push image in staging and deploy it') {
            agent any
            when {
                expression { GIT_BRANCH == 'origin/master' }
            }
            environment {
                HEROKU_API_KEY = credentials('HEROKU_API_KEY')
            }
            steps {
                sh '''
                    docker run --rm \
                      -e HEROKU_API_KEY=$HEROKU_API_KEY \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      heroku/heroku-cli:latest \
                      bash -c "
                        heroku container:login &&
                        heroku create $STAGING || echo project already exist &&
                        heroku container:push -a $STAGING web &&
                        heroku container:release -a $STAGING web
                      "
                '''
            }
        }

        stage('Push image in prod and deploy it') {
            agent any
            when {
                expression { GIT_BRANCH == 'origin/master' }
            }
            environment {
                HEROKU_API_KEY = credentials('HEROKU_API_KEY')
            }
            steps {
                sh '''
                    docker run --rm \
                      -e HEROKU_API_KEY=$HEROKU_API_KEY \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      heroku/heroku-cli:latest \
                      bash -c "
                        heroku container:login &&
                        heroku create $PRODUCTION || echo project already exist &&
                        heroku container:push -a $PRODUCTION web &&
                        heroku container:release -a $PRODUCTION web
                      "
                '''
            }
        }
    }
}
