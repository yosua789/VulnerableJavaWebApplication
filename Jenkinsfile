pipeline {
  agent {
    docker {
      image 'maven:3.9.6-eclipse-temurin-17'
      args '-u root:root'
    }
  }

  environment {
    SPOTBUGS_XML = 'target/spotbugsXml.xml'
    SPOTBUGS_XSL = 'target/spotbugs.xsl'
    SPOTBUGS_HTML = 'target/spotbugs.html'
  }

  stages {
    stage('Build & SpotBugs') {
      steps {
        echo '[STEP] Run SpotBugs'
        sh 'mvn clean verify'
      }
    }

    stage('Install xsltproc') {
      steps {
        echo '[STEP] Install xsltproc'
        sh 'apt-get update && apt-get install -y xsltproc'
      }
    }

    stage('Generate SpotBugs XSL') {
      steps {
        echo '[STEP] Create spotbugs.xsl'
        sh '''
          mkdir -p target
          cat <<EOF > ${SPOTBUGS_XSL}
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="yes"/>
  <xsl:template match="/">
    <html><body>
      <h2>SpotBugs Report</h2>
      <xsl:for-each select="//BugInstance">
        <div style="margin-bottom:10px;">
          <b><xsl:value-of select="@type"/></b> - 
          <xsl:value-of select="Class/@classname"/>:
          <xsl:value-of select="Method/@name"/>
        </div>
      </xsl:for-each>
    </body></html>
  </xsl:template>
</xsl:stylesheet>
EOF
        '''
      }
    }

    stage('Transform XML to HTML') {
      steps {
        echo '[STEP] Transform XML to HTML'
        sh 'xsltproc ${SPOTBUGS_XSL} ${SPOTBUGS_XML} > ${SPOTBUGS_HTML}'
      }
    }

    stage('Archive Report') {
      steps {
        echo '[STEP] Archive report'
        archiveArtifacts artifacts: "${SPOTBUGS_HTML}", onlyIfSuccessful: true
      }
    }

    stage('Publish HTML Report') {
      steps {
        echo '[STEP] Publish SpotBugs HTML'
        publishHTML(target: [
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
