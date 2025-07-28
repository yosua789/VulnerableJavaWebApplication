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
        SONAR_HOST_URL = 'http://localhost:9010'
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {

        stage('Checkout') {
            steps {
                echo '[STEP] Git Checkout'
                checkout scm
            }
        }

        stage('Install Tools') {
            steps {
                echo '[STEP] Install xsltproc, curl, pip'
                sh '''
                    apt-get update
                    apt-get install -y xsltproc curl python3-pip
                    pip3 install trufflehog
                '''
            }
        }

        stage('TruffleHog Secret Scan') {
            steps {
                echo '[STEP] Run TruffleHog'
                sh '''
                    mkdir -p target
                    trufflehog filesystem . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build & SpotBugs') {
            steps {
                echo '[STEP] Maven build and SpotBugs'
                sh 'mvn clean verify'
            }
        }

        stage('Download SpotBugs XSL') {
            steps {
                echo '[STEP] Download SpotBugs default.xsl'
                sh '''
                    mkdir -p target
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/4.7.3/etc/default.xsl -o $SPOTBUGS_XSL
                '''
            }
        }

        stage('Transform SpotBugs XML to HTML') {
            steps {
                echo '[STEP] Convert SpotBugs XML to HTML'
                sh '''
                    if [ -f $SPOTBUGS_XML ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML
                    else
                        echo "ERROR: SpotBugs XML report not found!"
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
                echo '[STEP] Archive SpotBugs & TruffleHog reports'
                archiveArtifacts artifacts: 'target/spotbugs.html,target/trufflehog.json', allowEmptyArchive: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo '[STEP] Publish SpotBugs HTML report'
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
