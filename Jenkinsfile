pipeline {
    environment {
        PORT_EXPOSED = "80"
        ID_DOCKER    = "alphabalde"
        IMAGE_NAME  = "alpinehelloworld"
        IMAGE_TAG   = "latest"
        STAGING     = "${ID_DOCKER}-staging"
        PRODUCTION  = "${ID_DOCKER}-production"
    }

    agent none

    stages {

        stage('Build image') {
            agent any
            steps {
                sh 'docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Run container based on builded image') {
            agent any
            steps {
                sh '''
                    echo "Clean Environment"
                    docker rm -f $IMAGE_NAME || echo "container does not exist"
                    docker run --name $IMAGE_NAME -d \
                      -p ${PORT_EXPOSED}:5000 \
                      -e PORT=5000 \
                      ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 5
                '''
            }
        }

        stage('Test image') {
            agent any
            steps {
                sh '''
                    curl http://172.17.0.1:${PORT_EXPOSED} | grep -qi "Hello world New!"
                '''
            }
        }

        stage('Clean Container') {
            agent any
            steps {
                sh '''
                    docker stop $IMAGE_NAME
                    docker rm $IMAGE_NAME
                '''
            }
        }

        stage('Login and Push Image on Docker Hub') {
            agent any
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USER" --password-stdin
                        docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        /* ===========================
           STAGING – HEROKU (FIX FINAL)
           =========================== */
        stage('Push image in staging and deploy it') {
            agent {
                docker {
                    image 'heroku/heroku:20'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([string(credentialsId: 'heroku_api_key', variable: 'HEROKU_API_KEY')]) {
                    sh '''
                        heroku container:login
                        heroku container:push -a alphabalde-staging web
                        heroku container:release -a alphabalde-staging web
                    '''
