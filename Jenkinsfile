pipeline {

    /************************************************************
     * VARIABLES GLOBALES DU PIPELINE
     * Elles sont accessibles dans tous les stages.
     ************************************************************/
    environment {
        PORT_EXPOSED = "80"                       // Port exposé sur la machine hôte
        ID_DOCKER = "alphabalde"                  // Nom de ton compte Docker Hub
        IMAGE_NAME = "alpinehelloworld"           // Nom de l'image Docker
        IMAGE_TAG = "latest"                      // Tag de l'image Docker

        // Noms des applications Heroku pour staging et production
        STAGING = "${ID_DOCKER}-staging"
        PRODUCTION = "${ID_DOCKER}-production"
    }

    // On ne définit pas d'agent global, chaque stage choisit son agent
    agent none

    stages {

        /************************************************************
         * 1. BUILD DE L'IMAGE DOCKER
         ************************************************************/
        stage('Build image') {
            agent any
            steps {
                script {
                    // Construction de l'image Docker locale
                    sh "docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        /************************************************************
         * 2. LANCEMENT DU CONTENEUR POUR TESTER L'IMAGE
         ************************************************************/
        stage('Run container based on built image') {
            agent any
            steps {
                script {
                    sh '''
                        echo "Clean Environment"
                        # On supprime un éventuel conteneur existant
                        docker rm -f $IMAGE_NAME || echo "Container does not exist"

                        # On lance le conteneur basé sur l'image construite
                        docker run --name $IMAGE_NAME -d -p ${PORT_EXPOSED}:5000 -e PORT=5000 ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG

                        # On attend quelques secondes que l'application démarre
                        sleep 5
                    '''
                }
            }
        }

        /************************************************************
         * 3. TEST DE L'APPLICATION DANS LE CONTENEUR
         ************************************************************/
        stage('Test image') {
            agent any
            steps {
                script {
                    sh """
                        # On vérifie que l'application répond bien
                        curl -s http://172.17.0.1:${PORT_EXPOSED} | grep -qi "Hello world New!"
                    """
                }
            }
        }

        /************************************************************
         * 4. NETTOYAGE DU CONTENEUR DE TEST
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
         * 5. PUSH DE L'IMAGE SUR DOCKER HUB
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
                            # Connexion à Docker Hub
                            echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USER" --password-stdin

                            # Push de l'image construite
                            docker push ${DOCKERHUB_USER}/$IMAGE_NAME:$IMAGE_TAG
                        """
                    }
                }
            }
        }

        /************************************************************
         * 6. DEPLOIEMENT EN STAGING SUR HEROKU
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

        # On supprime l'ancienne installation si elle existe
        rm -rf /usr/local/heroku

        # On installe proprement
        mv heroku /usr/local/heroku
        export PATH="/usr/local/heroku/bin:$PATH"

        echo "Heroku version:"
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
         * 7. DEPLOIEMENT EN PRODUCTION SUR HEROKU
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

        # On supprime l'ancienne installation si elle existe
        rm -rf /usr/local/heroku

        mv heroku /usr/local/heroku
        export PATH="/usr/local/heroku/bin:$PATH"

        echo "Heroku version:"
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
        post {
       success {
         slackSend (color: '#00FF00', message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}) - PROD URL => http://${PROD_APP_ENDPOINT} , STAGING URL => http://${STG_APP_ENDPOINT}")
      }
      failure {
            slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
     }   
   }  
 } // fin des stages
} // fin du pipeline
