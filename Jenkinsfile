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
                sh '''
                    set -x
                    mvn clean compile spotbugs:spotbugs || true
                '''
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                sh '''
                    set -x
                    trufflehog filesystem --json . > trufflehogscan.json || true
                '''
            }
        }

        stage('SonarQube Analysis') {
            environment {
                SONAR_HOST_URL = 'http://sonarqube:9000'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        set -x
                        mvn sonar:sonar \
                          -Dsonar.projectKey=VulnerableJavaWebApplication \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    '''
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
                sh '''
                    set -x
                    command -v docker || echo "Docker not available inside this Jenkins container."
                    docker build -t vulnerablejavawebapp . || true
                '''
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
