pipeline {
    agent any

    environment {
        SONARQUBE_URL = 'http://sonarqube:9000'
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
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
            steps {
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            mvn clean install sonar:sonar \
                                -Dsonar.projectKey=vulnerablejavawebapp \
                                -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
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
