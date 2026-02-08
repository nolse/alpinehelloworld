pipeline {
    agent any

    environment {
        HEROKU_API_KEY = credentials('heroku-api-key')
        IMAGE_NAME = 'alphabalde/alpinehelloworld:latest'
        PORT = '5000'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build image') {
            steps {
                sh """
                    docker rmi ${IMAGE_NAME} || true
                    docker build -t ${IMAGE_NAME} .
                """
            }
        }

        stage('Run container') {
            steps {
                sh """
                    docker rm -f alpinehelloworld || true
                    docker run -d --name alpinehelloworld -p ${PORT}:${PORT} -e PORT=${PORT} ${IMAGE_NAME}
                """
            }
        }

        stage('Test image') {
            steps {
                sh """
                    echo "Attente du démarrage de l'application..."
                    sleep 5
                    docker exec alpinehelloworld curl -s http://localhost:${PORT} | grep -iq 'hello world'
                    echo "Application OK"
                """
            }
        }

        stage('Clean container') {
            steps {
                sh "docker rm -f alpinehelloworld || true"
            }
        }

        stage('Push image in staging and deploy') {
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    sh """
                        echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com
                        export DOCKER_BUILDKIT=1
                        heroku container:push web -a eazytraining-staging-alpha --no-provenance
                        heroku container:release web -a eazytraining-staging-alpha
                    """
                }
            }
        }

        stage('Push image in prod and deploy') {
            when {
                expression { return env.BRANCH_NAME == 'main' } // Push prod uniquement depuis main
            }
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    sh """
                        echo \$HEROKU_API_KEY | docker login --username=_ --password-stdin registry.heroku.com
                        export DOCKER_BUILDKIT=1
                        heroku container:push web -a eazytraining-prod --no-provenance
                        heroku container:release web -a eazytraining-prod
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker rm -f alpinehelloworld || true"
        }
        success {
            echo 'Pipeline terminé avec succès !'
        }
        failure {
            echo 'Pipeline échoué, vérifier les logs.'
        }
    }
}
