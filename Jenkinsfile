pipeline {
  agent {
    docker {
      image 'maven:3.9.6-eclipse-temurin-17'
    }
  }

  environment {
    SPOTBUGS_XML = 'target/spotbugsXml.xml'
    SPOTBUGS_HTML = 'target/spotbugs.html'
    SPOTBUGS_XSL = 'target/spotbugs.xsl'
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/yosua789/VulnerableJavaWebApplication.git'
      }
    }

    stage('Maven Verify (Generate SpotBugs XML)') {
      steps {
        sh 'mvn clean verify'
      }
    }

    stage('Generate SpotBugs HTML') {
      steps {
        sh '''
          apt-get update && apt-get install -y xsltproc
          mkdir -p target
          cp src/main/resources/spotbugs.xsl "$SPOTBUGS_XSL"
          if [ -f "$SPOTBUGS_XML" ]; then
            xsltproc "$SPOTBUGS_XSL" "$SPOTBUGS_XML" > "$SPOTBUGS_HTML"
            echo "HTML report generated at $SPOTBUGS_HTML"
          else
            echo "No SpotBugs XML report found."
          fi
        '''
      }
    }

    stage('Archive Reports') {
      steps {
        archiveArtifacts artifacts: 'target/spotbugs.html', onlyIfSuccessful: true
      }
    }

    stage('Publish HTML Report') {
      steps {
        publishHTML (target: [
          reportDir: 'target',
          reportFiles: 'spotbugs.html',
          reportName: 'SpotBugs Report'
        ])
      }
    }
  }
}
