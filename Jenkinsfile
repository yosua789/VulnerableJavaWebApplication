pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarqube-token')
    }

    stages {

        stage('Checkout Source Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Maven + Compile + SpotBugs') {
            steps {
                sh '''
                    sudo apt-get update
                    sudo apt-get install -y maven default-jdk
                    mvn clean compile spotbugs:spotbugs
                '''
                archiveArtifacts artifacts: 'target/spotbugs*.xml, target/spotbugs*.html', allowEmptyArchive: true
            }
        }

        stage('Secret Scan with TruffleHog') {
            steps {
                sh '''
                    pip install --user trufflehog || true
                    ~/.local/bin/trufflehog filesystem . --json > trufflehogscan.json || true
                    cat trufflehogscan.json
                '''
                archiveArtifacts artifacts: 'trufflehogscan.json', allowEmptyArchive: true
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQubeServer') {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=vulnerable-java \
                            -Dsonar.sources=src \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.login=$SONAR_TOKEN \
                            -Dsonar.java.spotbugs.reportPaths=target/spotbugsXml.xml
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t vulnerable-java-application:0.1 .'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar, **/*.xml, **/*.json', allowEmptyArchive: true
            cleanWs()
        }
    }
}
