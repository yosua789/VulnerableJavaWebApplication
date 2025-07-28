pipeline {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
            args '-u root:root'
        }
    }

    environment {
        SPOTBUGS_XML = 'target/spotbugsXml.xml'
        SPOTBUGS_HTML = 'target/spotbugs.html'
        SPOTBUGS_XSL = 'target/spotbugs.xsl'
        SONAR_TOKEN = 'sqp_e3a2dd8c83cec020ad41d08031d5f09a3047a5a5'
    }

    stages {
        stage('Build & SpotBugs') {
            steps {
                echo "[STEP] Run mvn clean verify with SpotBugs plugin"
                sh 'mvn clean verify'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "[STEP] Install xsltproc"
                sh '''
                    apt-get update
                    apt-get install -y xsltproc
                '''
            }
        }

        stage('Generate SpotBugs XSL') {
            steps {
                echo "[STEP] Generate SpotBugs XSL file"
                sh """
                    mkdir -p target
                    cat > ${SPOTBUGS_XSL} <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html"/>
  <xsl:template match="/">
    <html>
      <head><title>SpotBugs Report</title></head>
      <body>
        <h1>SpotBugs Findings</h1>
        <table border="1">
          <tr><th>Type</th><th>Class</th><th>Method</th><th>Message</th></tr>
          <xsl:for-each select="BugCollection/BugInstance">
            <tr>
              <td><xsl:value-of select="@type"/></td>
              <td><xsl:value-of select="Class/@classname"/></td>
              <td><xsl:value-of select="Method/@name"/></td>
              <td><xsl:value-of select="LongMessage"/></td>
            </tr>
          </xsl:for-each>
        </table>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
EOF
                """
            }
        }

        stage('Transform XML to HTML') {
            steps {
                echo "[STEP] Transform SpotBugs XML to HTML"
                sh 'xsltproc ${SPOTBUGS_XSL} ${SPOTBUGS_XML} > ${SPOTBUGS_HTML}'
            }
        }

        stage('TruffleHog Secrets Scan') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --entrypoint='
                }
            }
            steps {
                echo "[STEP] Run TruffleHog Scan"
                sh '''
                    trufflehog --no-update filesystem . --json > trufflehogscan.json
                    cat trufflehogscan.json
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "[STEP] Run SonarQube Scan"
                sh """
                    mvn sonar:sonar \
                    -Dsonar.projectKey=VulnerableJavaWebApplication \
                    -Dsonar.host.url=http://localhost:9010 \
                    -Dsonar.login=${SONAR_TOKEN}
                """
            }
        }

        stage('Archive Report') {
            steps {
                echo "[STEP] Archive spotbugs.html"
                archiveArtifacts artifacts: "${SPOTBUGS_HTML}", fingerprint: true
                archiveArtifacts artifacts: "trufflehogscan.json", fingerprint: true
            }
        }

        stage('Publish HTML Report') {
            steps {
                echo "[STEP] Publish SpotBugs HTML Report"
                publishHTML(target: [
                    reportDir: 'target',
                    reportFiles: 'spotbugs.html',
                    reportName: 'SpotBugs Report'
                ])
            }
        }
    }
}
