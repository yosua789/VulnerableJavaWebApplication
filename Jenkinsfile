pipeline {
    agent none

    stages {

        stage('Maven Compile and SAST (SpotBugs)') {
            agent {
                docker {
                    image 'maven:3.8.7-openjdk-17'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'mvn compile spotbugs:spotbugs'
                archiveArtifacts artifacts: 'target/spotbugs.html', allowEmptyArchive: true
                archiveArtifacts artifacts: 'target/spotbugsXml.xml', allowEmptyArchive: true
            }
        }

        stage('Secret Scanning (TruffleHog)') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --entrypoint='
                }
            }
            steps {
                sh '''
                    trufflehog --no-update filesystem . --json > trufflehogscan.json || true
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
            environment {
                SONAR_TOKEN = credentials('sonarqube-token')
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
                            -Dsonar.host.url=$SONAR_HOST_URL \
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
            agent {
                docker {
                    image 'docker:20.10.24-dind'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t vulnerable-java-application:0.1 .'
            }
        }
    }
}
