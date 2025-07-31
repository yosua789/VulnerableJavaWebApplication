pipeline {
    agent any

    environment {
        SONARQUBE_URL = 'http://sonarqube:9000'
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('TruffleHog') {
            steps {
                sh 'trufflehog filesystem . || true'
            }
        }

        stage('Build + SonarQube') {
            environment {
                MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn clean install sonar:sonar'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t vulnerablejavawebapp .'
            }
        }
    }

    post {
        always {
            echo 'Archive artifacts & clean workspace...'
            archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
            cleanWs()
        }
        failure {
            echo 'Pipeline Failed. Check logs.'
        }
    }
}
