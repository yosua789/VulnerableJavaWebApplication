pipeline {
    agent none

    stages {
        stage('Maven Compile and SAST SpotBugs') {
            agent {
                label 'maven'
            }
            steps {
                sh 'mvn compile spotbugs:spotbugs'
                sh 'cp src/main/resources/spotbugs.xsl target/'
                sh '''
                    if [ -f target/spotbugsXml.xml ]; then
                        xsltproc target/spotbugs.xsl target/spotbugsXml.xml > target/spotbugs.html
                    else
                        echo "No SpotBugs XML report found."
                        exit 1
                    fi
                '''
                archiveArtifacts artifacts: 'target/spotbugs.html'
                archiveArtifacts artifacts: 'target/spotbugsXml.xml'
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

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'docker:dind'
                    args '-u root --privileged -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t vulnerable-java-application:0.1 .'
            }
        }
    }
}
