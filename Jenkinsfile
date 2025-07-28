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
                echo "[STEP] Clean, compile & generate SpotBugs report"
                sh '''
                    mvn clean compile spotbugs:spotbugs
                '''
            }
        }

        stage('Download SpotBugs XSL') {
            steps {
                echo "[STEP] Download SpotBugs XSL file"
                sh '''
                    mkdir -p target
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o ${SPOTBUGS_XSL}
                '''
            }
        }

        stage('Transform XML to HTML') {
            steps {
                echo "[STEP] Convert SpotBugs XML to HTML"

                sh '''
                    echo "[DEBUG] Check SpotBugs XML:"
                    ls -lh ${SPOTBUGS_XML} || echo "Missing XML"

                    echo "[DEBUG] Check SpotBugs XSL:"
                    head -n 10 ${SPOTBUGS_XSL} || echo "Missing XSL"

                    if [ ! -f "${SPOTBUGS_XML}" ]; then
                        echo "[ERROR] SpotBugs XML not found!"
                        exit 1
                    fi

                    echo "[STEP] Installing xsltproc"
                    apt-get update && apt-get install -y xsltproc

                    echo "[STEP] Converting XML ➝ HTML"
                    xsltproc ${SPOTBUGS_XSL} ${SPOTBUGS_XML} > ${SPOTBUGS_HTML}
                '''
            }
        }

        stage('Archive Report') {
            steps {
                echo "[STEP] Archiving SpotBugs HTML report"
                archiveArtifacts artifacts: "${SPOTBUGS_HTML}", allowEmptyArchive: false
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo "[STEP] Publishing SpotBugs HTML to Jenkins"
                publishHTML([
                    reportName: 'SpotBugs Report',
                    reportDir: 'target',
                    reportFiles: 'spotbugs.html',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: false
                ])
            }
        }
    }
}
