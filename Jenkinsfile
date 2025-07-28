pipeline {
    agent any
    environment {
        SONAR_HOST_URL = 'http://host.docker.internal:9010'
        SONAR_PROJECT_KEY = 'vulnerablejavawebapp'
        SONAR_TOKEN = credentials('sonarqube-token')
    }
    stages {
        stage('Cleanup Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Clone Repo') {
            steps {
                git url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git', branch: 'master'
            }
        }

        stage('Build & SonarQube') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh '''
                    mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                        -Dsonar.host.url=$SONAR_HOST_URL \
                        -Dsonar.login=$SONAR_TOKEN
                '''
            }
        }
    }
}
