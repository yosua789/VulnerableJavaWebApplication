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
        SONAR_HOST_URL = 'http://localhost:9000'
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
                echo '[STEP] Run TruffleHog locally'
                sh '''
                    apt-get update && apt-get install -y python3-pip
                    pip3 install trufflehog
                    mkdir -p target
                    trufflehog filesystem . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build & SpotBugs') {
            steps {
                echo '[STEP] Maven Build and SpotBugs Verification'
                sh 'mvn clean verify'
            }
        }

        stage('Copy SpotBugs XSL from Repo') {
            steps {
                echo '[STEP] Copy spotbugs.xsl from local repo'
                sh '''
                    mkdir -p target
                    cp src/main/resources/spotbugs.xsl $SPOTBUGS_XSL
                '''
            }
        }

        stage('Transform SpotBugs XML to HTML') {
            steps {
                echo '[STEP] XSLT Transformation'
                sh '''
                    apt-get install -y xsltproc
                    if [ -f $SPOTBUGS_XML ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML
                    else
                        echo "SpotBugs XML not found!"
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
                echo '[STEP] Archive TruffleHog + SpotBugs HTML'
                archiveArtifacts artifacts: 'target/spotbugs.html,target/trufflehog.json', allowEmptyArchive: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo '[STEP] Publish SpotBugs Report'
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
