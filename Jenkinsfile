pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        MAVEN_OPTS = "-Dmaven.repo.local=.m2/repository"
    }

    stages {
        stage('Install xsltproc') {
            steps {
                sh 'apt-get update && apt-get install -y xsltproc curl'
            }
        }

        stage('Build & SpotBugs') {
            steps {
                sh 'mvn clean verify'
            }
        }

        stage('Download SpotBugs XSL') {
            steps {
                sh '''
                    mkdir -p target
                    curl -sSL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o target/spotbugs.xsl
                '''
            }
        }

        stage('Generate HTML Report') {
            steps {
                sh '''
                    if [ -f target/spotbugsXml.xml ]; then
                        xsltproc target/spotbugs.xsl target/spotbugsXml.xml > target/spotbugs.html
                    else
                        echo "No SpotBugs XML report found."
                        exit 1
                    fi
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'target/spotbugs.html', onlyIfSuccessful: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                publishHTML (target: [
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'target',
                    reportFiles: 'spotbugs.html',
                    reportName: 'SpotBugs Report'
                ])
            }
        }
    }
}
