node('xcode') {
    ansiColor('xterm') {
        timestamps {
            stage('git') {
                checkout scm
            }

            stage('fetch') {
                sh 'swift package fetch'
            }

            stage('build) {
                sh 'swift build'
            }
        }
    }
}
