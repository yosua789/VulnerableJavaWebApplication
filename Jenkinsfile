pipeline {
  agent {
    docker {
      image 'maven:3.9.6-eclipse-temurin-17'
    }
  }
  environment {
    SONAR_HOST_URL = 'http://host.docker.internal:9010'
  }
  stages {
    stage('Clone Repo') {
      steps {
        git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
      }
    }
    stage('Build & Analyze') {
      steps {
        sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=vulnerablejavawebapp -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONARQUBE_TOKEN'
      }
    }
  }
}
