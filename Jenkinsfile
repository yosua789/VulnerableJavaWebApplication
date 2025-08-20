pipeline {
  agent any

  environment {
    FAIL_ON_ISSUES = "false"
  }

  stages {
    stage('Clean') {
      steps {
        cleanWs()
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    // ========== OWASP Dependency-Check ==========
    stage('SCA - Dependency-Check') {
      agent {
        docker {
          image 'owasp/dependency-check:latest'
          args '--entrypoint=""'
          reuseNode true
        }
      }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          sh '''
            mkdir -p dependency-check-report
            /usr/share/dependency-check/bin/dependency-check.sh \
              --project "MyApp" \
              --scan . \
              --format ALL \
              --out dependency-check-report \
              --log dependency-check-report/dependency-check.log \
              --failOnCVSS 11 || true
          '''
        }
      }
      post {
        always {
          script {
            if (fileExists('dependency-check-report/dependency-check-report.html')) {
              publishHTML(target: [
                reportDir: 'dependency-check-report',
                reportFiles: 'dependency-check-report.html',
                reportName: 'Dependency-Check Report'
              ])
            }
          }
        }
      }
    }

    // ========== Trivy (Filesystem Scan) ==========
    stage('SCA - Trivy (filesystem)') {
      agent {
        docker {
          image 'aquasec/trivy:latest'
          args '--entrypoint=""'
          reuseNode true
        }
      }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          sh '''
            rm -f trivy-fs.txt trivy-fs.sarif

            # Scan vuln only (skip secret scan biar cepet)
            trivy fs --scanners vuln --no-progress --exit-code 0 \
              --severity HIGH,CRITICAL . | tee trivy-fs.txt

            trivy fs --scanners vuln --no-progress --exit-code 0 \
              --severity HIGH,CRITICAL --format sarif -o trivy-fs.sarif .
          '''
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'trivy-fs.*', fingerprint: true
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline Done. Result: ${currentBuild.currentResult}"
    }
  }
}
