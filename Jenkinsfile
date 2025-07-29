pipeline {
    agent none

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {

        stage('Checkout Source Code') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Compile & SpotBugs') {
            agent {
                docker {
                    image 'maven:3.8.7-openjdk-17'
                }
            }
            steps {
                sh 'mvn compile spotbugs:spotbugs'
                archiveArtifacts artifacts: 'target/spotbugs*.xml, target/spotbugs*.html', allowEmptyArchive: true
            }
        }

        stage('Secret Scan with TruffleHog') {
            agent any
            steps {
                sh '''
                    pip install --user trufflehog || true
                    ~/.local/bin/trufflehog --no-update filesystem . --json > trufflehogscan.json || true
                    cat trufflehogscan.json
                '''
                archiveArtifacts artifacts: 'trufflehogscan.json', allowEmptyArchive: true
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'maven:3.8.7-openjdk-17'
                }
            }
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQubeServer') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=vulnerable-java \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.login=$SONAR_TOKEN \
                            -Dsonar.java.spotbugs.reportPaths=target/spotbugsXml.xml
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            agent any
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            agent any
            steps {
                sh 'docker build -t vulnerable-java-application:0.1 .'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar, **/*.xml, **/*.json', allowEmptyArchive: true
            cleanWs()
        }
    }
}
