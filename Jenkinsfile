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
                    mvn clean compile spotbugs:spotbugs || echo "SpotBugs failed, continuing..."
                '''
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                sh '''
                    trufflehog filesystem . --json > trufflehogscan.json || echo "TruffleHog failed, continuing..."
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
                        mvn sonar:sonar \
                            -Dsonar.projectKey=vulnerablejavawebapp \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.token=$SONAR_TOKEN || echo "SonarQube analysis failed, continuing..."
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "Check SonarQube Quality Gate..."
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t vulnerablejavawebapp . || echo "Docker build failed"
                '''
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
