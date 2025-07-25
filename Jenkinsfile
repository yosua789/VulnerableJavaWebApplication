pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u 0:0'
        }
    }

    environment {
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & SpotBugs') {
            steps {
                sh '''
                    # Clean and build with SpotBugs plugin
                    mvn clean verify

                    # Copy SpotBugs XSL to target
                    mkdir -p target
                    cp src/main/resources/spotbugs.xsl target/

                    # Transform XML to HTML (if exists)
                    if [ -f target/spotbugsXml.xml ]; then
                        xsltproc target/spotbugs.xsl target/spotbugsXml.xml > target/spotbugs.html
                    else
                        echo "No SpotBugs XML report found."
                    fi
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'target/spotbugs.html', allowEmptyArchive: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                publishHTML(target: [
                    reportName: 'SpotBugs Report',
                    reportDir: 'target',
                    reportFiles: 'spotbugs.html',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: true
                ])
            }
        }
    }
}
