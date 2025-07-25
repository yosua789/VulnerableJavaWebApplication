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
        stage('SpotBugs SAST HTML') {
            steps {
                sh '''
                    apt-get update && apt-get install -y curl xsltproc
                    mkdir -p src/main/resources
                    curl -sSL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o src/main/resources/spotbugs.xsl
                    mvn clean verify
                '''
            }
        }

        stage('Generate HTML Report') {
            steps {
                sh '''
                    mkdir -p target
                    cp src/main/resources/spotbugs.xsl target/

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
                publishHTML(target: [
                    reportDir: 'target',
                    reportFiles: 'spotbugs.html',
                    reportName: 'SpotBugs Report'
                ])
            }
        }
    }
}
