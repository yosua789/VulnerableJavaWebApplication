pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        SPOTBUGS_XML = 'target/spotbugsXml.xml'
        SPOTBUGS_HTML = 'target/spotbugs.html'
        SPOTBUGS_XSL = 'target/spotbugs.xsl'
    }

    stages {

        stage('Build & SpotBugs') {
            steps {
                echo "[STEP] Run mvn clean verify with SpotBugs plugin"
                sh 'mvn clean verify'
            }
        }

        stage('Download SpotBugs XSL') {
            steps {
                echo "[STEP] Download SpotBugs XSL file"
                sh '''
                    mkdir -p target
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/main/etc/spotbugs.xsl -o ${SPOTBUGS_XSL}
                '''
            }
        }

        stage('Transform XML to HTML') {
            steps {
                echo "[STEP] Transform SpotBugs XML to HTML"
                sh '''
                    if [ -f "${SPOTBUGS_XML}" ]; then
                        apt-get update && apt-get install -y xsltproc > /dev/null
                        xsltproc ${SPOTBUGS_XSL} ${SPOTBUGS_XML} > ${SPOTBUGS_HTML}
                    else
                        echo "No SpotBugs XML report found."; exit 1
                    fi
                '''
            }
        }

        stage('Archive Report') {
            steps {
                echo "[STEP] Archive HTML report"
                archiveArtifacts artifacts: "${SPOTBUGS_HTML}", onlyIfSuccessful: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo "[STEP] Publish SpotBugs HTML to Jenkins UI"
                publishHTML(target: [
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
