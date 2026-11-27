// ClaudeClang CI - every stage runs inside the claudeclangbuild image built
// from docker/Dockerfile (same image as local development).
// A PR may be merged only when this pipeline succeeds.

def gitflowViolation() {
    if (!env.CHANGE_ID) { return null }
    def src = env.CHANGE_BRANCH
    def dst = env.CHANGE_TARGET
    def ok = (src ==~ /feature\/.+/ && dst == 'develop') ||
             (src ==~ /(release|hotfix)\/.+/ && (dst == 'main' || dst == 'develop'))
    return ok ? null : "Gitflow violation: ${src} -> ${dst} (allowed: feature/* -> develop, release/*|hotfix/* -> main|develop)"
}

pipeline {
    agent {
        dockerfile {
            dir 'docker'
            filename 'Dockerfile'
            additionalBuildArgs '-t claudeclangbuild'
        }
    }
    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timeout(time: 60, unit: 'MINUTES')
    }
    environment {
        // Release-bound code must be human-reviewed (HITL @human_review Done).
        REQUIRE_HUMAN_REVIEW = "${(env.CHANGE_TARGET == 'main' || env.BRANCH_NAME == 'main' || env.BRANCH_NAME ==~ /(release|hotfix)\/.+/) ? '1' : '0'}"
    }
    stages {
        stage('Gitflow') {
            steps {
                script {
                    def v = gitflowViolation()
                    if (v) { error(v) }
                    echo "branch=${env.BRANCH_NAME} pr=${env.CHANGE_ID ?: '-'} target=${env.CHANGE_TARGET ?: '-'} requireHumanReview=${env.REQUIRE_HUMAN_REVIEW}"
                }
            }
        }
        stage('Build') {
            steps { sh 'bash tools/quality_gate.sh build' }
        }
        stage('Static analysis (Cppcheck)') {
            steps { catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') { sh 'bash tools/quality_gate.sh static' } }
        }
        stage('Metrics (Lizard)') {
            steps { catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') { sh 'bash tools/quality_gate.sh metrics' } }
        }
        stage('Comment ratio (CLOC)') {
            steps { catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') { sh 'bash tools/quality_gate.sh comments' } }
        }
        stage('HITL comments') {
            steps { catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') { sh 'bash tools/quality_gate.sh hitl' } }
        }
        stage('Tests & coverage') {
            // one invocation so the instrumented build is shared by all suites
            steps { catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') { sh 'bash tools/quality_gate.sh unit tdd integration system' } }
        }
    }
    post {
        always {
            junit allowEmptyResults: true, testResults: 'build/cov/coverage/*/junit.xml'
            recordIssues enabledForFailure: true, tools: [cppCheck(pattern: 'build/reports/cppcheck.xml')]
            script {
                ['unit', 'tdd', 'integration', 'system'].each { s ->
                    if (fileExists("build/cov/coverage/${s}/html/index.html")) {
                        publishHTML(target: [reportDir: "build/cov/coverage/${s}/html", reportFiles: 'index.html',
                                             reportName: "Coverage - ${s}", keepAll: true, alwaysLinkToLastBuild: true,
                                             allowMissing: true])
                    }
                }
            }
            archiveArtifacts allowEmptyArchive: true, artifacts: 'build/reports/**, build/cov/coverage/*/summary.*, build/cov/coverage/*/junit.xml'
        }
    }
}
