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
        SONAR_HOST_URL = 'http://localhost:9000' // Sesuaikan URL SonarQube kamu
        SONAR_TOKEN = credentials('sonarqube-token') // Sesuaikan dengan Jenkins credential ID
    }

    stages {

        stage('Checkout') {
            steps {
                echo '[STEP] Git Checkout'
                checkout scm
            }
        }

        stage('Install TruffleHog') {
            steps {
                echo '[STEP] Install & Run TruffleHog'
                sh '''
                    apt-get update && apt-get install -y python3-pip
                    pip3 install trufflehog
                '''
            }
        }

        stage('Run TruffleHog') {
            steps {
                echo '[STEP] Scanning Secret via TruffleHog'
                sh '''
                    mkdir -p target
                    trufflehog filesystem . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build & Run SpotBugs') {
            steps {
                echo '[STEP] Run mvn build & SpotBugs (with FindSecBugs)'
                sh 'mvn clean verify'
            }
        }

        stage('Generate SpotBugs HTML Report') {
            steps {
                echo '[STEP] Transform SpotBugs XML to HTML'
                sh '''
                    apt-get update && apt-get install -y xsltproc curl
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o $SPOTBUGS_XSL
                    if [ -f $SPOTBUGS_XML ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML
                    else
                        echo "SpotBugs XML report not found."
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
                            -Dsonar.projectKey=${env.SONAR_PROJECT_KEY} \
                            -Dsonar.host.url=${env.SONAR_HOST_URL} \
                            -Dsonar.login=${env.SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Archive Report') {
            steps {
                echo '[STEP] Archive Reports'
                archiveArtifacts artifacts: 'target/*.json,target/*.html,target/*.xml', allowEmptyArchive: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo '[STEP] Publish SpotBugs HTML Report'
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
