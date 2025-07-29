pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('Build with Maven + SpotBugs') {
            steps {
                sh 'mvn clean compile spotbugs:spotbugs'
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                sh 'trufflehog filesystem . || true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=VulnerableJavaWebApplication \
                        -Dsonar.host.url=http://localhost:9010 \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t vulnerable-app .'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            cleanWs()
            echo 'Pipeline Finished.'
        }

        failure {
            echo 'Pipeline Failed. Check logs.'
        }
    }
}
