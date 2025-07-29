pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token') // Pastikan ID ini sesuai
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('Build with Maven + SpotBugs') {
            steps {
                // Tetap jalan walau SpotBugs error
                sh 'mvn clean compile spotbugs:spotbugs || echo "SpotBugs failed, continuing..."'
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                // Pakai URL Git untuk TruffleHog (bukan filesystem)
                sh 'trufflehog git https://github.com/yosua789/VulnerableJavaWebApplication.git --json > trufflehogscan.json || echo "TruffleHog failed, continuing..."'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_HOST_URL = 'http://sonarqube:9000'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=vulnerablejavawebapp \
                        -Dsonar.host.url=$SONAR_HOST_URL \
                        -Dsonar.token=$SONAR_TOKEN
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
                sh 'docker build -t vulnerablejavawebapp .'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar, **/*.json, **/zapreport.html, **/spotbugs*.xml', allowEmptyArchive: true
            cleanWs()
            echo 'Pipeline Finished.'
        }
        failure {
            echo 'Pipeline Failed. Check logs.'
        }
    }
}
