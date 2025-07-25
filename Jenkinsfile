pipeline {
  agent {
    docker {
      image 'maven:3.9.6-eclipse-temurin-17'
      args '-u root:root'
    }
  }

  environment {
    REPORT_DIR = 'target'
    SPOTBUGS_XML = "${env.REPORT_DIR}/spotbugsXml.xml"
    SPOTBUGS_HTML = "${env.REPORT_DIR}/spotbugs.html"
    SPOTBUGS_XSL = "${env.REPORT_DIR}/spotbugs.xsl"
  }

  stages {
    stage('Build & SpotBugs') {
      steps {
        sh 'mkdir -p src/main/resources'
        sh 'curl -sSL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl -o src/main/resources/spotbugs.xsl'
        sh 'mvn clean verify'
      }
    }

    stage('Generate SpotBugs HTML') {
      steps {
        sh 'mkdir -p target'
        sh 'cp src/main/resources/spotbugs.xsl $SPOTBUGS_XSL'
        sh '''
          if [ -f "$SPOTBUGS_XML" ]; then
            xsltproc "$SPOTBUGS_XSL" "$SPOTBUGS_XML" > "$SPOTBUGS_HTML"
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
        publishHTML([
          allowMissing: false,
          alwaysLinkToLastBuild: true,
          keepAll: true,
          reportDir: 'target',
          reportFiles: 'spotbugs.html',
          reportName: 'SpotBugs Report'
        ])
      }
    }
  }
}
