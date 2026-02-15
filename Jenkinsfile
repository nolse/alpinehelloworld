pipeline {

    /************************************************************
     * VARIABLES GLOBALES DU PIPELINE
     ************************************************************/
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

        /************************************************************
         * 1. BUILD DE L'IMAGE DOCKER
         ************************************************************/
        stage('Build image') {
            agent any
            steps {
                script {
                    sh "docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        /************************************************************
         * 2. RUN DU CONTENEUR POUR TEST
         ************************************************************/
        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Clean Environment"
                        docker rm -f $IMAGE_NAME || echo "Container does not exist"

                        docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 \
                            -e PORT=5000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG

                        sleep 5
                    '''
                }
            }
        }

        /************************************************************
         * 3. TEST DE L'IMAGE
         ************************************************************/
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

        /************************************************************
         * 4. CLEAN DU CONTENEUR DE TEST
         ************************************************************/
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

        /************************************************************
         * 5. PUSH SUR DOCKER HUB
         ************************************************************/
        stage('Login and Push Image on Docker Hub') {
            agent any
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_PASSWORD'
                    )
                ]) {
                    script {
                        sh """
                            echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USER" --password-stdin
                            docker push ${DOCKERHUB_USER}/$IMAGE_NAME:$IMAGE_TAG
                        """
                    }
                }
            }
        }

        /************************************************************
         * 6. DEPLOIEMENT STAGING
         ************************************************************/
        stage('Push image in staging and deploy it') {
            when {
                expression { env.GIT_BRANCH == 'origin/master' }
            }
            agent any
            environment {
                HEROKU_API_KEY = credentials('heroku_api_key')
            }
            steps {
                script {
                    sh '''
                        echo "=== Installation du Heroku CLI standalone ==="
                        curl https://cli-assets.heroku.com/heroku-linux-x64.tar.gz -o heroku.tar.gz
                        tar -xzf heroku.tar.gz

                        rm -rf /usr/local/heroku
                        mv heroku /usr/local/heroku
                        export PATH="/usr/local/heroku/bin:$PATH"

                        heroku --version

                        echo "=== Connexion Heroku ==="
                        heroku container:login

                        echo "=== Création de l'app staging si nécessaire ==="
                        heroku create $STAGING || echo "project already exist"

                        echo "=== Push de l'image Docker ==="
                        heroku container:push -a $STAGING web

                        echo "=== Release de l'image ==="
                        heroku container:release -a $STAGING web
                    '''
                }
            }
        }

        /************************************************************
         * 7. DEPLOIEMENT PRODUCTION
         ************************************************************/
        stage('Push image in production and deploy it') {
            when {
                expression { env.GIT_BRANCH == 'origin/master' }
            }
            agent any
            environment {
                HEROKU_API_KEY = credentials('heroku_api_key')
            }
            steps {
                script {
                    sh '''
                        echo "=== Installation du Heroku CLI standalone ==="
                        curl https://cli-assets.heroku.com/heroku-linux-x64.tar.gz -o heroku.tar.gz
                        tar -xzf heroku.tar.gz

                        rm -rf /usr/local/heroku
                        mv heroku /usr/local/heroku
                        export PATH="/usr/local/heroku/bin:$PATH"

                        heroku --version

                        echo "=== Connexion Heroku ==="
                        heroku container:login

                        echo "=== Création de l'app production si nécessaire ==="
                        heroku create $PRODUCTION || echo "project already exist"

                        echo "=== Push de l'image Docker ==="
                        heroku container:push -a $PRODUCTION web

                        echo "=== Release de l'image ==="
                        heroku container:release -a $PRODUCTION web
                    '''
                }
            }
        }
    } // fin des stages

    /************************************************************
     * POST ACTIONS (SUCCESS / FAILURE)
     ************************************************************/
    post {
        success {
            slackSend(
                color: '#00FF00',
                message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
            )
        }
        failure {
            slackSend(
                color: '#FF0000',
                message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
            )
        }
    }

} // fin du pipeline
