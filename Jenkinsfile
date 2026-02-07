pipeline { // AUTOMATISATION

    agent none

    environment {
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG  = "latest"
        STAGING    = "eazytraining-staging-alpha"
        PRODUCTION = "eazytraining-prod-alpha"
    }
    stages { // DEVELOPPEMENT

        stage('Build image') {
            agent any
            steps {
                script {
                    sh '''
                    docker build -t alphabalde/${IMAGE_NAME}:${IMAGE_TAG} .
                    docker ps
                    sleep 5
                    '''
                }
            }
        }

        stage('Run container based on builded image') {
            agent any
            steps {
                script {
                    sh '''
                        docker run --name $IMAGE_NAME -d -p 80:5000 -e PORT=5000 alphabalde/$IMAGE_NAME:$IMAGE_TAG
                        sleep 5
                    '''
                }
            }
        }

        stage('Test image') {
            agent any
            steps {
                script {
                    sh '''
                        curl http://172.17.0.1:80 | grep -iq "hello world!"
                    '''
                }
            }
        }

        stage('Clean container') {
            agent any
            steps {
                script {
                    sh '''
                        docker stop $IMAGE_NAME || true
                        docker rm $IMAGE_NAME || true
                    '''
                }
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
                script {
                    sh '''
                        heroku container:login
                        heroku create $STAGING || echo "project already exist"
                        heroku container:push -a $STAGING web
                        heroku container:release -a $STAGING web
                    '''
                }
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
                script {
                    sh '''
                        heroku container:login
                        heroku create $PRODUCTION || echo "project already exist"
                        heroku container:push -a $PRODUCTION web
                        heroku container:release -a $PRODUCTION web
                    '''
                }
            }
        }
    }
}
