pipeline {
  agent any

  environment {
    SONAR_TOKEN     = credentials('sonarqube-token')
    SONAR_HOST_URL  = 'http://host.docker.internal:9010'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'master', url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
      }
    }

    stage('SpotBugs Analysis') {
      steps {
        sh 'mvn clean compile spotbugs:spotbugs'
      }
    }

    stage('TruffleHog') {
      steps {
        sh 'docker run --rm -v $PWD:/pwd trufflesecurity/trufflehog:latest filesystem /pwd --json > trufflehog.json || true'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN'
        }
      }
    }
  }
}
