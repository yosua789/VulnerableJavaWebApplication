pipeline {
    agent none

    stages {
        stage('Maven Compile + SAST (SpotBugs HTML)') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                }
            }
            steps {
                sh '''
                    mvn clean compile spotbugs:spotbugs || echo "SpotBugs failed"
                    ls -lh target/spotbugs.xml || echo "XML report not found"
                '''
                archiveArtifacts artifacts: 'target/spotbugs.xml', allowEmptyArchive: true
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
                sh '''
                    trufflehog --no-update filesystem . --json > trufflehogscan.json || echo "Trufflehog failed"
                    cat trufflehogscan.json || echo "No secrets found"
                '''
                archiveArtifacts artifacts: 'trufflehogscan.json', allowEmptyArchive: true
            }
        }

        stage('SCA (OWASP Dependency-Check)') {
            agent {
                docker {
                    image 'owasp/dependency-check:latest'
                    args '--entrypoint='
                }
            }
            steps {
                sh '''
                    /usr/share/dependency-check/bin/dependency-check.sh \
                        --scan src \
                        --project "VulnerableJavaWebApplication" \
                        --format ALL \
                        --out . \
                        --exclude node_modules --exclude target || echo "Dependency Check Failed"
                '''
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

        stage('Run Docker Image') {
            agent {
                docker {
                    image 'docker:dind'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh '''
                    docker stop vulnerable-container || true
                    docker rm -f vulnerable-container || true
                    while docker ps -a --format '{{.Names}}' | grep -w vulnerable-container; do
                      echo "Waiting for container to be fully removed..."
                      sleep 1
                    done
                    docker run --rm --name vulnerable-container -d -p 8081:8080 vulnerable-java-application:0.1
                '''
            }
        }
    }
}
