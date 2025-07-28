pipeline {
    agent any
    environment {
        SONAR_HOST_URL = 'http://host.docker.internal:9010'
        SONAR_LOGIN = credentials('sonarqube-token') // ID di Jenkins Credentials
    }
    stages {
        stage('SonarQube Analysis') {
            steps {
                withDockerContainer('maven:3.9.6-eclipse-temurin-17') {
                    sh '''
                        mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=your-project-key \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_LOGIN}
                    '''
                }
            }
        }
    }
}
