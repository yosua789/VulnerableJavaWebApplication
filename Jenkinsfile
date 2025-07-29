pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token') // Pastikan ini ada di Jenkins credentials
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('Build with Maven + SpotBugs') {
            steps {
                // Tetap lanjut walau SpotBugs error
                sh 'mvn clean compile spotbugs:spotbugs || echo "SpotBugs failed, continuing..."'
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                // Gunakan URL Git, bukan local path
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
                        -Dsonar.token=$SONAR_TOKEN \
                        -Dsonar.host.url=$SONAR_HOST_URL
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Check SonarQube Quality Gate...'
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
            archiveArtifacts artifacts: '**/target/*.jar, **/*.json, **/spotbugs*.xml', allowEmptyArchive: true
            cleanWs()
            echo 'Pipeline Finished.'
        }
        failure {
            echo 'Pipeline Failed. Check logs.'
        }
    }
}
