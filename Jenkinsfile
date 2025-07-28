pipeline {
  agent {
    docker {
      image 'maven:3.9.6-eclipse-temurin-17'
    }
  }
  environment {
    SONAR_HOST_URL = 'http://host.docker.internal:9010'
    SONAR_SCANNER_OPTS = '-Dsonar.projectKey=vulnerablejavawebapp'
  }
  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
      }
    }
    stage('Build') {
      steps {
        sh 'mvn clean install'
      }
    }
    stage('SpotBugs') {
      steps {
        sh 'mvn com.github.spotbugs:spotbugs-maven-plugin:4.7.3.2:spotbugs'
      }
    }
    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh 'mvn sonar:sonar'
        }
      }
    }
  }
}
