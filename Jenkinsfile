pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token') // ID dari Jenkins credentials
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo 'checkout source code...'
                git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('Build with Maven + SpotBugs') {
            steps {
                echo '🔨 Build with Maven + SpotBugs...'
                sh 'mvn clean compile spotbugs:spotbugs || echo "⚠ SpotBugs failed, continuing..."'
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                echo 'Scan secrets with TruffleHog...'
                sh 'trufflehog git https://github.com/yosua789/VulnerableJavaWebApplication.git --json > trufflehogscan.json || echo "⚠ TruffleHog failed, continuing..."'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_HOST_URL = 'http://sonarqube:9000'
            }
            steps {
                echo 'Run SonarQube analysis...'
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
                echo 'Check SonarQube Quality Gate...'
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Build Docker image...'
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
