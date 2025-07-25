stage('SpotBugs SAST HTML') {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
        }
    }
    steps {
        sh '''
            apt-get update && apt-get install -y xsltproc curl

            # Get XSL file
            curl -sSL https://raw.githubusercontent.com/spotbugs/spotbugs/master/spotbugs/etc/default.xsl \
              -o target/spotbugs.xsl

            # Run SpotBugs with HTML
            mvn clean compile spotbugs:spotbugs spotbugs:check || echo "SpotBugs failed"

            # Transform XML ➝ HTML manually
            xsltproc target/spotbugs.xsl target/spotbugsXml.xml > target/site/spotbugs.html || echo "XSLT failed"

            ls -lh target/spotbugsXml.xml || echo "No XML"
            ls -lh target/site/spotbugs.html || echo "No HTML"
        '''
        archiveArtifacts artifacts: 'target/spotbugsXml.xml', allowEmptyArchive: true
        archiveArtifacts artifacts: 'target/site/spotbugs.html', allowEmptyArchive: true
        publishHTML(target: [
            reportName: 'SpotBugs Report',
            reportDir: 'target/site',
            reportFiles: 'spotbugs.html',
            keepAll: true,
            alwaysLinkToLastBuild: true,
            allowMissing: true
        ])
    }
}
