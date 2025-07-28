pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        SPOTBUGS_HTML = 'target/spotbugs.html'
        SPOTBUGS_XML  = 'target/spotbugsXml.xml'
        SPOTBUGS_XSL  = 'target/spotbugs.xsl'
        SONAR_PROJECT_KEY = 'vulnerablejavawebapp'
        SONAR_HOST_URL = 'http://localhost:9000' // Ganti sesuai instance kamu
        SONAR_TOKEN = credentials('sonarqube-token') // simpan token SonarQube di Jenkins credentials
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
                    apt-get update && apt-get install -y python3-pip
                    pip3 install trufflehog
                    trufflehog filesystem . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build & SpotBugs') {
            steps {
                echo '[STEP] Build and Run SpotBugs'
                sh 'mvn clean verify'
            }
        }

        stage('Generate SpotBugs HTML') {
            steps {
                echo '[STEP] Transform SpotBugs XML to HTML'
                sh '''
                    apt-get update && apt-get install -y xsltproc curl
                    mkdir -p target
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o $SPOTBUGS_XSL
                    if [ -f $SPOTBUGS_XML ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML
                    else
                        echo "No SpotBugs XML report found"
                        exit 1
                    fi
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                echo '[STEP] SonarQube Analysis'
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

        stage('Archive Reports') {
            steps {
                echo '[STEP] Archive spotbugs.html & trufflehog.json'
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
