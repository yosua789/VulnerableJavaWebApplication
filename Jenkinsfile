pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
        SONAR_URL = 'http://your-sonarqube-server:9000'
        PROJECT_KEY = 'VulnerableJavaWebApplication'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git', branch: 'master'
            }
        }

        stage('Build with Maven + SpotBugs') {
            steps {
                sh 'mvn clean compile spotbugs:spotbugs'
            }
            post {
                always {
                    archiveArtifacts artifacts: '**/target/spotbugsXml.xml', allowEmptyArchive: true
                }
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                sh 'trufflehog git https://github.com/yosua789/VulnerableJavaWebApplication.git --json > trufflehog-report.json || true'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trufflehog-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${PROJECT_KEY} \
                        -Dsonar.host.url=${SONAR_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t vulnerable-java-app .'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo 'Pipeline Failed. Check logs.'
        }
        success {
            echo 'Pipeline Succeeded!'
        }
    }
}
