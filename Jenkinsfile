node('xcode') {
    ansiColor('xterm') {
        timestamps {
            stage('git') {
                checkout scm
                sh 'git submodule update --init --recursive'
            }

            stage('fetch') {
                sh 'swift package fetch'
            }

            stage('lint') {
                withCredentials([
                    [$class: 'StringBinding', credentialsId: 'github', variable: 'CHECKS_GITHUB_TOKEN']
                ]) {
                    sh 'Checks/Shared/core.js Checks/Shared/swiftlint.js'
                }
            }

            stage('build') {
                sh 'swift build'
            }

            stage('tests') {
                sh 'swift test'
            }
        }
    }
}
