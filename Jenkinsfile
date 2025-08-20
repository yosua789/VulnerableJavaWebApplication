pipeline {
  agent any
  options { skipDefaultCheckout(true) }

  environment {
    // ubah ke 'true' kalau mau build image dan scan image-nya juga
    BUILD_IMAGE    = 'false'
    FAIL_ON_ISSUES = 'false'   // set 'true' untuk gagal kalau scanner return non-zero
  }

  stages {
    stage('Clean') {
      steps { cleanWs() }
    }

    stage('Checkout') {
      steps {
        checkout([$class: 'GitSCM',
          branches: [[name: '*/master']],
          extensions: [[$class: 'CloneOption', shallow: false, noTags: false]],
          userRemoteConfigs: [[url: 'https://github.com/yosua789/VulnerableJavaWebApplication.git']]
        ])
      }
    }

    // ===== SCA: OWASP Dependency-Check (scan dependency seluruh repo) =====
    stage('SCA - Dependency-Check (repo)') {
      agent {
        docker {
          image 'owasp/dependency-check:latest'
          reuseNode true
          // cache NVD + temp agar lebih cepat/stabil
          args "-v ${WORKSPACE}/.odc:/usr/share/dependency-check/data -v ${WORKSPACE}/.odc-temp:/tmp"
        }
      }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          script {
            sh '''
              set -e
              mkdir -p dependency-check-report
              # update DB (kalau gagal, lanjut saja biar tidak blok)
              /usr/share/dependency-check/bin/dependency-check.sh --updateonly || true

              # scan seluruh repo (otomatis deteksi pom.xml, package.json, requirements.txt, dll)
              set +e
              /usr/share/dependency-check/bin/dependency-check.sh \
                --project "Testing-Sast" \
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

    // ===== SCA: Trivy (filesystem) — TANPA build image =====
    stage('SCA - Trivy (filesystem)') {
      agent {
        docker {
          image 'aquasec/trivy:latest'
          reuseNode true
          // kosongkan entrypoint agar container tetap hidup; cache biar cepat
          args '--entrypoint="" -v ${WORKSPACE}/.trivy-cache:/root/.cache/trivy'
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

              # (opsional) hasil SARIF untuk integrasi tooling
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

    // ===== OPSIONAL: build & scan Docker image (aktifkan dengan BUILD_IMAGE='true') =====
    stage('Build Docker Image') {
      when { expression { return env.BUILD_IMAGE == 'true' } }
      steps {
        sh 'docker version'
        sh 'docker build -t testing-sast:latest .'
      }
    }

    stage('SCA - Trivy (image)') {
      when { expression { return env.BUILD_IMAGE == 'true' } }
      agent {
        docker {
          image 'aquasec/trivy:latest'
          reuseNode true
          args '--entrypoint="" -v /var/run/docker.sock:/var/run/docker.sock -v ${WORKSPACE}/.trivy-cache:/root/.cache/trivy'
        }
      }
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
          script {
            def ec = sh(returnStatus: true, script: '''
              set +e
              trivy image --no-progress --exit-code 0 \
                --severity HIGH,CRITICAL testing-sast:latest | tee trivy-image.txt
            ''')
            echo "Trivy image scan exit code: ${ec}"
          }
        }
      }
      post {
        always {
          script {
            if (fileExists('trivy-image.txt')) { archiveArtifacts artifacts: 'trivy-image.txt', fingerprint: true }
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline selesai. Result: ${currentBuild.currentResult}"
    }
  }
}
