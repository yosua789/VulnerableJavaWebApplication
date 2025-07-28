pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        SONAR_PROJECT_KEY = 'vulnerablejavawebapp'
        SONAR_HOST_URL = 'http://localhost:9010' // GANTI ke 9000 jika tidak pakai mapping
        SONAR_TOKEN = credentials('sonarqube-token')

        SPOTBUGS_HTML = 'target/spotbugs.html'
        SPOTBUGS_XML  = 'target/spotbugsXml.xml'
        SPOTBUGS_XSL  = 'src/main/resources/spotbugs.xsl'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '[STEP] Git Checkout'
                checkout scm
            }
        }

        stage('TruffleHog Scan') {
            steps {
                echo '[STEP] Running TruffleHog...'
                sh '''
                    apt-get update && apt-get install -y python3-pip git
                    pip3 install trufflehog
                    mkdir -p target
                    trufflehog git . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build and SpotBugs') {
            steps {
                echo '[STEP] Maven Clean Verify & SpotBugs'
                sh 'mvn clean verify'
            }
        }

        stage('Transform SpotBugs XML to HTML') {
            steps {
                echo '[STEP] Transform SpotBugs XML to HTML using XSL'
                sh '''
                    apt-get update && apt-get install -y xsltproc
                    if [ -f $SPOTBUGS_XML ] && [ -f $SPOTBUGS_XSL ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML
                    else
                        echo "Missing SpotBugs XML or XSL"
                        exit 1
                    fi
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '[STEP] Run SonarQube Scan'
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn sonar:sonar \
                          -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                          -Dsonar.host.url=$SONAR_HOST_URL \
                          -Dsonar.login=$SONAR_TOKEN
                    '''
                }
            }
        }

        stage('Archive Report') {
            steps {
                echo '[STEP] Archive SpotBugs & TruffleHog Reports'
                archiveArtifacts artifacts: 'target/spotbugs.html,target/trufflehog.json', allowEmptyArchive: true
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
