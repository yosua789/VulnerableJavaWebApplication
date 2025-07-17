pipeline {
    agent none
    stages {
        stage('Maven Compile and SAST Spotbugs') {
            agent {
                label 'maven'
            }
            steps {
                sh 'mvn compile spotbugs:spotbugs'
                archiveArtifacts artifacts: 'target/spotbugs.html'
                archiveArtifacts artifacts: 'target/spotbugs.xml'
            }
        }

        stage('Secret Scanning') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --entrypoint='
                }
            }
            steps {
                sh 'trufflehog --no-update filesystem . --json > trufflehogscan.json'
                sh 'cat trufflehogscan.json'
                archiveArtifacts artifacts: 'trufflehogscan.json'
            }
        }

        stage('SCA') {
            agent {
                docker {
                    image 'owasp/dependency-check:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --entrypoint='
                }
            }
            steps {
                sh '/usr/share/dependency-check/bin/dependency-check.sh --scan . --project "VulnerableJavaWebApplication" --format ALL'
                archiveArtifacts artifacts: 'dependency-check-report.html'
                archiveArtifacts artifacts: 'dependency-check-report.json'
                archiveArtifacts artifacts: 'dependency-check-report.xml'
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

