pipeline {
    agent none

    stages {
        stage('Maven Compile and SAST Spotbugs') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                }
            }
            steps {
                sh 'mvn clean compile spotbugs:spotbugs'
                sh 'ls -R target/ || echo "target folder not found"'
                archiveArtifacts artifacts: 'target/spotbugs.xml', allowEmptyArchive: false
            }
        }

        stage('Secret Scanning (TruffleHog)') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '--entrypoint='
                }
            }
            steps {
                sh 'trufflehog --no-update filesystem . --json > trufflehogscan.json || echo "Trufflehog failed"'
                sh 'cat trufflehogscan.json || echo "No scan result"'
                archiveArtifacts artifacts: 'trufflehogscan.json', allowEmptyArchive: true
            }
        }

        stage('SCA (OWASP Dependency Check)') {
            agent {
                docker {
                    image 'owasp/dependency-check:latest'
                    args '--entrypoint='
                }
            }
            steps {
                sh '''
                    /usr/share/dependency-check/bin/dependency-check.sh \
                        --scan . \
                        --project "VulnerableJavaWebApplication" \
                        --format ALL \
                        --out .
                '''.stripIndent()
                archiveArtifacts artifacts: 'dependency-check-report.*', allowEmptyArchive: true
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
