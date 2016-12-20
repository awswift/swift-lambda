node('xcode') {
    ansiColor('xterm') {
        timestamps {
            stage('git') {
                checkout scm
                sh 'git submodule update --init'
            }

            stage('fetch') {
                sh 'swift package fetch'
            }

            stage('lint') {
                sh 'Checks/Shared/core.js Checks/Shared/swiftlint.js'
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
