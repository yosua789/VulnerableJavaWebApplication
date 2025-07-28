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
        SONAR_HOST_URL = 'http://host.docker.internal:9010' // Bind ke 9010
        SONAR_TOKEN = credentials('sonarqube-token') // Token disimpan di Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                echo '[STEP] Git Checkout'
                git branch: 'master', url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
            }
        }

        stage('TruffleHog Secret Scan') {
            steps {
                echo '[STEP] Running TruffleHog...'
                sh '''
                    pip3 install --no-cache-dir trufflehog
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

        stage('Download SpotBugs XSL') {
            steps {
                echo '[STEP] Download SpotBugs default.xsl'
                sh '''
                    mkdir -p target
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o $SPOTBUGS_XSL || curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/4.7.0/etc/default.xsl -o $SPOTBUGS_XSL
                '''
            }
        }

        stage('Transform SpotBugs XML to HTML') {
            steps {
                echo '[STEP] Transform SpotBugs XML to HTML'
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
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
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
