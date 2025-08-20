pipeline {
  agent any
  options { skipDefaultCheckout(true) }

  environment {
    FAIL_ON_ISSUES = 'false'   // set 'true' kalau mau fail saat scanner return non-zero
  }

  stages {
    stage('Clean') {
      steps { cleanWs() }
    }

    stage('Checkout (master)') {
      steps {
        checkout([$class: 'GitSCM',
          branches: [[name: '*/master']],
          extensions: [[$class: 'CloneOption', shallow: false, noTags: false]],
          userRemoteConfigs: [[url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git']]
        ])
      }
    }

    // ===== SCA: OWASP Dependency-Check (scan repo) =====
    stage('SCA - Dependency-Check') {
      agent {
        docker {
          image 'owasp/dependency-check:latest'
          reuseNode true
          // TIDAK ADA -v volume (aman untuk path workspace yang mengandung spasi)
          // entrypoint default sudah cukup untuk Dependency-Check
        }
      }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          script {
            sh '''
              set -e
              mkdir -p dependency-check-report
              # Update DB (kalau gagal jangan block pipeline)
              /usr/share/dependency-check/bin/dependency-check.sh --updateonly || true

              # Scan seluruh repo; --failOnCVSS 11 = temuan tidak bikin non-zero
              set +e
              /usr/share/dependency-check/bin/dependency-check.sh \
                --project "VulnerableJavaWebApplication" \
                --scan . \
                --format ALL \
                --out dependency-check-report \
                --log dependency-check-report/dependency-check.log \
                --failOnCVSS 11
              echo $? > .dc_exit
            '''
            def rc = readFile('.dc_exit').trim()
            echo "Dependency-Check exit code: ${rc}"
            if (env.FAIL_ON_ISSUES == 'true' && rc != '0') {
              error "Fail build (policy) karena Dependency-Check exit ${rc}"
            }
          }
        }
      }
      post {
        always {
          script {
            if (fileExists('dependency-check-report/dependency-check.log')) {
              archiveArtifacts artifacts: 'dependency-check-report/dependency-check.log', fingerprint: true
            }
            if (fileExists('dependency-check-report/dependency-check-report.html')) {
              publishHTML(target: [
                reportDir: 'dependency-check-report',
                reportFiles: 'dependency-check-report.html',
                reportName: 'Dependency-Check Report'
              ])
            } else {
              echo "Dependency-Check HTML report tidak ditemukan. Cek dependency-check-report/dependency-check.log"
            }
          }
        }
      }
    }

    // ===== SCA: Trivy filesystem (tanpa Docker image) =====
    stage('SCA - Trivy (filesystem)') {
      agent {
        docker {
          image 'aquasec/trivy:latest'
          reuseNode true
          args '--entrypoint=""'  // kosongkan entrypoint agar container tetap hidup di Jenkins
          // TIDAK ADA -v volume (aman untuk path workspace yang mengandung spasi)
        }
      }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          script {
            sh 'rm -f trivy-fs.txt trivy-fs.sarif || true'
            def ec = sh(returnStatus: true, script: '''
              set +e
              trivy fs --no-progress --exit-code 0 \
                --severity HIGH,CRITICAL . | tee trivy-fs.txt

              # (opsional) SARIF untuk integrasi ke tools lain
              trivy fs --no-progress --exit-code 0 \
                --severity HIGH,CRITICAL --format sarif -o trivy-fs.sarif .
            ''')
            echo "Trivy FS scan exit code: ${ec}"
            if (env.FAIL_ON_ISSUES == 'true' && ec != 0) {
              error "Fail build (policy) karena Trivy FS exit ${ec}"
            }
          }
        }
      }
      post {
        always {
          script {
            if (fileExists('trivy-fs.txt'))   { archiveArtifacts artifacts: 'trivy-fs.txt', fingerprint: true }
            if (fileExists('trivy-fs.sarif')) { archiveArtifacts artifacts: 'trivy-fs.sarif', fingerprint: true }
          }
        }
      }
    }
  }

  post {
    always { echo "Pipeline selesai. Result: ${currentBuild.currentResult}" }
  }
}
