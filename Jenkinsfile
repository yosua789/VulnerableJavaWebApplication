pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        SPOTBUGS_HTML = 'target/spotbugs.html'
    }

    stages {
        stage('Build & SpotBugs') {
            steps {
                echo "[STEP] Run mvn clean verify with SpotBugs plugin"
                sh 'mvn clean verify'
            }
        }

        stage('Archive Report') {
            steps {
                echo "[STEP] Archive SpotBugs HTML"
                archiveArtifacts artifacts: "${SPOTBUGS_HTML}", allowEmptyArchive: false
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo "[STEP] Publish SpotBugs Report"
                publishHTML(target: [
                    reportName           : 'SpotBugs Report',
                    reportDir            : 'target',
                    reportFiles          : 'spotbugs.html',
                    keepAll              : true,
                    allowMissing         : false,
                    alwaysLinkToLastBuild: true
                ])
            }
        }
    }
}
