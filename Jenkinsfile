pipeline {
    agent any
    environment {
        HEROKU_API_KEY = credentials('heroku-api-key')
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
                    docker rmi -f alphabalde/alpinehelloworld:latest || true
                    docker build -t alphabalde/alpinehelloworld:latest .
                """
            }
        }

        stage('Run container') {
            steps {
                sh """
                    docker rm -f alpinehelloworld || true
                    docker run -d --name alpinehelloworld -p 5000:5000 -e PORT=5000 alphabalde/alpinehelloworld:latest
                """
            }
        }

        stage('Test image') {
            steps {
                sh """
                    echo "Attente du démarrage de l'application..."
                    sleep 5
                    docker exec alpinehelloworld curl -s http://localhost:5000 | grep -iq 'hello world'
                    echo "Application OK"
                """
            }
        }

        stage('Clean container') {
            steps {
                sh "docker rm -f alpinehelloworld || true"
            }
        }

        stage('Push image to staging and deploy') {
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    sh """
                        echo \$HEROKU_API_KEY | heroku container:login
                        heroku container:push web -a eazytraining-staging-alpha
                        heroku container:release web -a eazytraining-staging-alpha
                    """
                }
            }
        }

        stage('Push image to prod and deploy') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([string(credentialsId: 'heroku-api-key', variable: 'HEROKU_API_KEY')]) {
                    sh """
                        echo \$HEROKU_API_KEY | heroku container:login
                        heroku container:push web -a eazytraining-prod
                        heroku container:release web -a eazytraining-prod
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker rm -f alpinehelloworld || true"
            echo "Pipeline terminé"
        }
        failure {
            echo "Pipeline échoué, vérifier les logs"
        }
    }
}
