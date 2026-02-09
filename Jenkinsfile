pipeline {
     environment {
       PORT_EXPOSED = "80"   
       ID_DOCKER = "alphabalde"
       IMAGE_NAME = "alpinehelloworld"
       IMAGE_TAG = "latest"
//       PORT_EXPOSED = "80" à paraméter dans le job
       STAGING = "${ID_DOCKER}-staging"
       PRODUCTION = "${ID_DOCKER}-production"
     }
     agent none
     stages {
         stage('Build image') {
             agent any
             steps {
                script {
                  sh 'docker build -t ${ID_DOCKER}/$IMAGE_NAME:$IMAGE_TAG .'
                }
             }
        }
          
        stage('Run container based on builded image') {
            agent any
            steps {
               script {
                 sh '''
                    echo "Clean Environment"
                    docker rm -f $IMAGE_NAME || echo "container does not exist"
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
                    curl http://172.17.0.1:${PORT_EXPOSED} | grep -qi "Hello world New!"
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
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub',   // ton ID Jenkins pour Docker Hub
            usernameVariable: 'DOCKERHUB_USER',
            passwordVariable: 'DOCKERHUB_PASSWORD'
        )]) {
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
    steps {
        withCredentials([string(credentialsId: 'heroku_api_key', variable: 'HEROKU_API_KEY')]) {
            sh '''
                # Installation Heroku CLI
                npm install -g heroku

                # Login Heroku (utilise docker CLI du node Jenkins)
                heroku container:login

                # Push image vers le registry Heroku
                heroku container:push -a alphabalde-staging web

                # Release sur Heroku
                heroku container:release -a alphabalde-staging web
            '''
        }
    }
}          

     stage('Push image in production and deploy it') {
       when {
              expression { GIT_BRANCH == 'origin/production' }
            }
      agent any
      environment {
          HEROKU_API_KEY = credentials('heroku_api_key')
      }  
      steps {
          script {
            sh '''
              npm i -g heroku@7.68.0
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
