pipeline { // AUTOMATISATION CI/CD

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
                // Construire l'image Docker à partir du Dockerfile
                sh '''
                    docker build -t alphabalde/${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Run container based on built image') {
            agent any
            steps {
                // Définir un nom unique pour le conteneur avec le numéro de build
                // Supprimer tout conteneur existant portant ce nom pour éviter les conflits
                sh '''
                    CONTAINER_NAME=${IMAGE_NAME}-${BUILD_NUMBER}
                    docker rm -f $CONTAINER_NAME || true
                    docker run --name $CONTAINER_NAME -d \
                        -p 80:5000 \
                        -e PORT=5000 \
                        alphabalde/${IMAGE_NAME}:${IMAGE_TAG}
                    sleep 30
                '''
            }
        }

        stage('Test image') {
    steps {
        sh '''
            # Nom du conteneur utilisé dans les stages précédents
            CONTAINER_NAME=alpinehelloworld-28

            echo "Attente que l'application soit disponible dans le conteneur..."

            # Boucle d'attente : on teste toutes les 2 secondes si l'app répond
            # Cela évite les faux échecs si Gunicorn démarre lentement
            for i in {1..10}; do
                if docker exec $CONTAINER_NAME curl -s http://localhost:5000 > /tmp/app_response.txt; then
                    echo "Application accessible ✅"
                    break
                fi
                echo "Application pas encore prête... tentative $i"
                sleep 2
            done

            echo "Vérification du contenu de la réponse HTTP..."

            # Vérifie que la page contient bien "hello world!"
            docker exec $CONTAINER_NAME curl -s http://localhost:5000 | grep -iq "hello world!"

            echo "Test fonctionnel réussi 🎉"
        '''
    }
}
        stage('Clean container') {
            agent any
            steps {
                // Nettoyer le conteneur après le test pour ne pas polluer Docker
                sh '''
                    CONTAINER_NAME=${IMAGE_NAME}-${BUILD_NUMBER}
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true
                '''
            }
        }

        stage('Push image in staging and deploy') {
            agent any
            when {
                expression { GIT_BRANCH == 'origin/master' }
            }
            environment {
                HEROKU_API_KEY = credentials('HEROKU_API_KEY')
            }
            steps {
                // Push de l'image sur Heroku staging et déploiement
                sh '''
                    docker login --username=_ --password-stdin registry.heroku.com <<< $HEROKU_API_KEY
                    docker tag alphabalde/${IMAGE_NAME}:${IMAGE_TAG} registry.heroku.com/${STAGING}/web
                    docker push registry.heroku.com/${STAGING}/web
                    heroku container:release -a $STAGING web
                '''
            }
        }

        stage('Push image in prod and deploy') {
            agent any
            when {
                expression { GIT_BRANCH == 'origin/master' }
            }
            environment {
                HEROKU_API_KEY = credentials('HEROKU_API_KEY')
            }
            steps {
                // Push de l'image sur Heroku production et déploiement
                sh '''
                    docker login --username=_ --password-stdin registry.heroku.com <<< $HEROKU_API_KEY
                    docker tag alphabalde/${IMAGE_NAME}:${IMAGE_TAG} registry.heroku.com/${PRODUCTION}/web
                    docker push registry.heroku.com/${PRODUCTION}/web
                    heroku container:release -a $PRODUCTION web
                '''
            }
        }
    }
}
