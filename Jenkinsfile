pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('Build with Maven + SpotBugs') {
            steps {
                sh 'mvn clean compile spotbugs:spotbugs || echo "SpotBugs failed, continuing..."'
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                sh 'trufflehog filesystem --directory . --json > trufflehogscan.json || echo "TruffleHog failed, continuing..."'
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
                script {
                    echo 'Check SonarQube Quality Gate...'
                    def qualityGate = waitForQualityGate()
                    if (qualityGate.status != 'OK') {
                        echo "WARNING: Quality Gate = ${qualityGate.status}. Pipeline tetap lanjut."
                    } else {
                        echo "Quality Gate PASSED: ${qualityGate.status}"
                    }
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
            archiveArtifacts artifacts: '**/target/*.jar, **/*.json, **/zapreport.html, **/spotbugs*.xml', allowEmptyArchive: true
            cleanWs()
            echo 'Pipeline Finished.'
        }
        failure {
            echo 'Pipeline Failed. Check logs.'
        }
    }
}
