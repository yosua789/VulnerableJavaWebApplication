pipeline {
    agent any

    tools {
        maven 'Maven3'
        jdk 'JDK17'
    }

    environment {
        MAVEN_OPTS = "-Dmaven.repo.local=.m2/repository"
    }

    stages {
        stage('Build and SpotBugs') {
            steps {
                sh 'mvn clean verify'
            }
        }

        stage('Transform XML to HTML') {
            steps {
                sh '''
                apt-get update && apt-get install -y xsltproc

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
