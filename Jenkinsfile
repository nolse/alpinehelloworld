pipeline {
    environment {
        PORT_EXPOSED = "80"
        ID_DOCKER = "alphabalde"
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG = "latest"
        STAGING = "${ID_DOCKER}-staging"
        PRODUCTION = "${ID_DOCKER}-production"
    }

    agent none

    stages {

        stage('Build image') {
            agent any
            steps {
                script {
                    sh "docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Clean Environment"
                        docker rm -f $IMAGE_NAME || echo "Container does not exist"
                        docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG
                        sleep 5
                    '''
                }
            }
        }

        stage('Test image') {
            agent any
            steps {
                script {
                    sh """
                        curl -s http://172.17.0.1:${PORT_EXPOSED} | grep -qi "Hello world New!"
                    """
                }
            }
        }

        stage('Clean Container') {
            agent any
            steps {
                script {
                    sh '''
                        docker stop $IMAGE_NAME
                        docker rm $IMAGE_NAME
                    '''
                }
            }
        }

        stage('Login and Push Image on Docker Hub') {
            agent any
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                    script {
                        sh """
                            echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USER" --password-stdin
                            docker push ${DOCKERHUB_USER}/$IMAGE_NAME:$IMAGE_TAG
                        """
                    }
                }
            }
        }

        stage('Push image in staging and deploy it') {
            agent any
            steps {
                withCredentials([string(credentialsId: 'heroku_api_key', variable: 'HEROKU_API_KEY')]) {
                    script {
                        docker.image('docker:24.0.5-dind').inside('-v /var/run/docker.sock:/var/run/docker.sock') {
                            sh """
                                apt-get update && apt-get install -y curl xz-utils
                                curl https://cli-assets.heroku.com/install.sh | sh
                                export HEROKU_API_KEY=$HEROKU_API_KEY
                                heroku container:login
                                heroku container:push web --app $STAGING
                                heroku container:release web --app $STAGING
                            """
                        }
                    }
                }
            }
        }

        stage('Push image in production and deploy it') {
            when {
                expression { env.GIT_BRANCH == 'origin/production' }
            }
            agent any
            steps {
                withCredentials([string(credentialsId: 'heroku_api_key', variable: 'HEROKU_API_KEY')]) {
                    script {
                        docker.image('docker:24.0.5-dind').inside('-v /var/run/docker.sock:/var/run/docker.sock') {
                            sh """
                                apt-get update && apt-get install -y curl xz-utils
                                curl https://cli-assets.heroku.com/install.sh | sh
                                export HEROKU_API_KEY=$HEROKU_API_KEY
                                heroku container:login
                                heroku container:push web --app $PRODUCTION
                                heroku container:release web --app $PRODUCTION
                            """
                        }
                    }
                }
            }
        }
    }
}
