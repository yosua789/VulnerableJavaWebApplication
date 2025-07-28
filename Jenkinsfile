pipeline {
    agent none

    stages {
        stage('Maven Compile and SAST SpotBugs') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-17'
                    args '-u root:root'
                }
            }
            steps {
                sh '''
                    apt-get update && apt-get install -y xsltproc

                    mvn compile spotbugs:spotbugs

                    mkdir -p target
                    cp src/main/resources/spotbugs.xsl target/

                    if [ -f target/spotbugsXml.xml ]; then
                        xsltproc target/spotbugs.xsl target/spotbugsXml.xml > target/spotbugs.html
                    else
                        echo "No SpotBugs XML report found."
                        exit 1
                    fi
                '''

                archiveArtifacts artifacts: 'target/spotbugsXml.xml'
                archiveArtifacts artifacts: 'target/spotbugs.html'
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
                sh '''
                    trufflehog --no-update filesystem . --json > trufflehogscan.json
                    cat trufflehogscan.json
                '''
                archiveArtifacts artifacts: 'trufflehogscan.json'
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:dind'
                    args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t vulnerable-java-application:0.1 .'
            }
        }
    }
}
