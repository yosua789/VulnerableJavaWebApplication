pipeline {
    agent none

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
        SONAR_SCANNER_HOME = tool name: 'SonarScanner'
    }

    stages {
        stage('Maven Compile and SAST (SpotBugs)') {
            agent {
                label 'maven'
            }
            steps {
                sh 'mvn compile spotbugs:spotbugs'

                archiveArtifacts artifacts: 'target/spotbugs.html'
                archiveArtifacts artifacts: 'target/spotbugsXml.xml'
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
                    trufflehog --no-update filesystem . --json > trufflehogscan.json
                    cat trufflehogscan.json
                '''
                archiveArtifacts artifacts: 'trufflehogscan.json'
            }
        }

        stage('SonarQube Analysis') {
            agent {
                label 'maven'
            }
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    sh """
                        ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
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
                    image 'docker:dind'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t vulnerable-java-application:0.1 .'
            }
        }
    }
}
