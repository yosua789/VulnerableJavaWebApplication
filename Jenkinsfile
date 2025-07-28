pipeline {
    agent any

    environment {
        SPOTBUGS_HTML = 'target/spotbugs.html'
        SPOTBUGS_XML  = 'target/spotbugsXml.xml'
        SPOTBUGS_XSL  = 'spotbugs.xsl'
        SONAR_PROJECT_KEY = 'vulnerablejavawebapp'
        SONAR_HOST_URL = 'http://host.docker.internal:9010'
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {
        stage('Checkout') {
            steps {
                echo '[STEP] Git Checkout'
                checkout scm
            }
        }

        stage('TruffleHog Secret Scan') {
            steps {
                echo '[STEP] Running TruffleHog...'
                sh '''
                    pip3 install --user trufflehog
                    ~/.local/bin/trufflehog filesystem . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build & SpotBugs') {
            steps {
                echo '[STEP] Build and Run SpotBugs'
                sh 'mvn clean verify'
            }
        }

        stage('Copy SpotBugs XSL') {
            steps {
                echo '[STEP] Copy SpotBugs XSL for HTML transform'
                writeFile file: "${SPOTBUGS_XSL}", text: libraryResource('spotbugs-default.xsl')
            }
        }

        stage('Transform SpotBugs XML to HTML') {
            steps {
                echo '[STEP] Generate SpotBugs HTML'
                sh '''
                    apt-get update && apt-get install -y xsltproc
                    if [ -f $SPOTBUGS_XML ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML
                    else
                        echo "No SpotBugs XML report found"
                        exit 1
                    fi
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '[STEP] Run SonarQube Scan'
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                            -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.login=$SONAR_TOKEN
                    """
                }
            }
        }

        stage('Archive Reports') {
            steps {
                echo '[STEP] Archive Reports'
                archiveArtifacts artifacts: 'target/spotbugs.html,target/spotbugsXml.xml,target/trufflehog.json', allowEmptyArchive: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo '[STEP] Publish SpotBugs HTML'
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
