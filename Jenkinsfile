stage('Maven Compile + SAST (SpotBugs HTML)') {
    agent {
        docker {
            image 'maven:3.9.6-eclipse-temurin-17'
        }
    }
    steps {
        sh '''
            mkdir -p src/main/resources

            curl -sSL https://raw.githubusercontent.com/spotbugs/spotbugs/master/etc/default.xsl \
                -o src/main/resources/spotbugs.xsl

            file src/main/resources/spotbugs.xsl || echo "File corrupt?"
            head -n 5 src/main/resources/spotbugs.xsl

            mvn clean verify || echo "Maven verify failed"

            mv target/site/spotbugsXml.html target/site/spotbugs.html || echo "Rename failed"

            ls -lh target/spotbugsXml.xml || echo "XML report not found"
            ls -lh target/site/spotbugs.html || echo "HTML report not found"
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
