pipeline { 
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
                sh "docker build -t alphabalde/${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Run container locally') {
            agent any
            steps {
                sh """
                    docker run --name $IMAGE_NAME -d -p 80:5000 -e PORT=5000 alphabalde/${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 5
                """
            }
        }

        stage('Test image') {
            agent any
            steps {
                sh 'curl http://172.17.0.1:80 | grep -iq "hello world!"'
            }
        }

        stage('Clean container') {
            agent any
            steps {
                sh "docker stop $IMAGE_NAME || true && docker rm $IMAGE_NAME || true"
            }
        }

        stage('Push image to staging and deploy') {
            agent any
            when {
                expression { env.GIT_BRANCH == 'origin/master' }
            }
            environment {
                HEROKU_API_KEY = credentials('HEROKU_API_KEY')
            }
            steps {
                sh """
                    # Login Docker to Heroku
                    echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com

                    # Tag and push to Heroku Registry
                    docker tag alphabalde/\$IMAGE_NAME:\$IMAGE_TAG registry.heroku.com/\$STAGING/web
                    docker push registry.heroku.com/\$STAGING/web

                    # Release app via Heroku API
                    curl -n -X PATCH https://api.heroku.com/apps/\$STAGING/formation \
                        -H "Accept: application/vnd.heroku+json; version=3" \
                        -H "Authorization: Bearer \$HEROKU_API_KEY" \
                        -H "Content-Type: application/json" \
                        -d '{"updates":[{"type":"web","docker_image":"registry.heroku.com/'\$STAGING'/web"}]}'
                """
            }
        }

        stage('Push image to prod and deploy') {
            agent any
            when {
                expression { env.GIT_BRANCH == 'origin/master' }
            }
            environment {
                HEROKU_API_KEY = credentials('HEROKU_API_KEY')
            }
            steps {
                sh """
                    # Login Docker to Heroku
                    echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com

                    # Tag and push to Heroku Registry
                    docker tag alphabalde/\$IMAGE_NAME:\$IMAGE_TAG registry.heroku.com/\$PRODUCTION/web
                    docker push registry.heroku.com/\$PRODUCTION/web

                    # Release app via Heroku API
                    curl -n -X PATCH https://api.heroku.com/apps/\$PRODUCTION/formation \
                        -H "Accept: application/vnd.heroku+json; version=3" \
                        -H "Authorization: Bearer \$HEROKU_API_KEY" \
                        -H "Content-Type: application/json" \
                        -d '{"updates":[{"type":"web","docker_image":"registry.heroku.com/'\$PRODUCTION'/web"}]}'
                """
            }
        }

    }
}
