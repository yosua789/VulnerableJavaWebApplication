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
        SONAR_HOST_URL    = 'http://host.docker.internal:9010'
        SONAR_TOKEN       = credentials('sonarqube-token')
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
                echo '[STEP] Install TruffleHog'
                sh '''
                    apt-get update && apt-get install -y python3-pip git curl
                    pip3 install trufflehog
                '''
            }
        }

        stage('Run TruffleHog Scan') {
            steps {
                echo '[STEP] Run TruffleHog'
                sh '''
                    mkdir -p target
                    trufflehog filesystem . --json > target/trufflehog.json || true
                '''
            }
        }

        stage('Build & Run SpotBugs') {
            steps {
                echo '[STEP] Maven Build + SpotBugs'
                sh 'mvn clean verify'
            }
        }

        stage('Download SpotBugs XSL') {
            steps {
                echo '[STEP] Download SpotBugs default.xsl'
                sh '''
                    mkdir -p target
                    curl -sSfL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/spotbugs.xsl -o $SPOTBUGS_XSL || true
                '''
            }
        }

        stage('Transform SpotBugs XML to HTML') {
            steps {
                echo '[STEP] Convert SpotBugs XML to HTML'
                sh '''
                    apt-get update && apt-get install -y xsltproc
                    if [ -f $SPOTBUGS_XML ]; then
                        xsltproc $SPOTBUGS_XSL $SPOTBUGS_XML > $SPOTBUGS_HTML || true
                    else
                        echo "No SpotBugs XML found, skipping transform"
                    fi
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '[STEP] Run SonarQube Scan'
                sh '''
                    mvn sonar:sonar \
                        -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                        -Dsonar.host.url=$SONAR_HOST_URL \
                        -Dsonar.login=$SONAR_TOKEN || true
                '''
            }
        }

        stage('Archive Report') {
            steps {
                echo '[STEP] Archive SpotBugs HTML and TruffleHog JSON'
                archiveArtifacts artifacts: 'target/spotbugs.html,target/trufflehog.json', allowEmptyArchive: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo '[STEP] Publish SpotBugs HTML Report'
                publishHTML(target: [
                    reportName           : 'SpotBugs Report',
                    reportDir            : 'target',
                    reportFiles          : 'spotbugs.html',
                    keepAll              : true,
                    alwaysLinkToLastBuild: true,
                    allowMissing         : true
                ])
            }
        }
    }
}
