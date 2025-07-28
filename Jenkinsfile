pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        SPOTBUGS_XSL_URL = 'https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl'
    }

    stages {
        stage('Build and SpotBugs Scan') {
            steps {
                sh 'mvn clean compile spotbugs:spotbugs'
                sh 'mkdir -p target'
                sh 'curl -sSL $SPOTBUGS_XSL_URL -o target/spotbugs.xsl'
                sh 'apt-get update && apt-get install -y xsltproc'
                sh '''
                    if [ -f target/spotbugsXml.xml ]; then
                        xsltproc target/spotbugs.xsl target/spotbugsXml.xml > target/spotbugs.html
                    else
                        echo "No SpotBugs report found"
                        exit 1
                    fi
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                archiveArtifacts artifacts: 'target/spotbugs.html', onlyIfSuccessful: true
                archiveArtifacts artifacts: 'target/spotbugsXml.xml', onlyIfSuccessful: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                publishHTML target: [
                    reportDir: 'target',
                    reportFiles: 'spotbugs.html',
                    reportName: 'SpotBugs Report',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ]
            }
        }
    }
}
