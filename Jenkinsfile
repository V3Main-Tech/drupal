pipeline {
  environment {
    imagename = "v3mainproducts/drupal"
    registryCredential = 'docker_hub_creds'
    dockerImage = ''
    namespace = 'v3md-drupal'
  }
  agent any
  stages {
    stage('Cloning Git') {
      steps {
        git([url: 'https://github.com/V3Main-Tech/drupal.git', branch: 'drupal_poc', credentialsId: 'github_creds'])

      }
    }
    stage('Building image') {
      steps{
        script {
          dockerImage = docker.build imagename
        }
      }
    }
    stage('Deploy Image') {
      steps{
        script {
          docker.withRegistry( '', registryCredential ) {
            dockerImage.push("$BUILD_NUMBER")
             dockerImage.push('latest')

          }
        }
      }
    }
    stage('Deploy to K8s')
		{
			steps{
				sshagent(['k8s-jenkins'])
				{
				    sh("kubectl apply -f deployment.yml")
            sh("kubectl apply -f mysql.yml")
				}
			}
    }
    stage('Remove Unused docker image') {
      steps{
        sh "docker rmi $imagename:$BUILD_NUMBER"
         sh "docker rmi $imagename:latest"

      }
    }
  }
}
