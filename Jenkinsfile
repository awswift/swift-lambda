def doit() {
    stage('git') {
        checkout scm
        sh 'git submodule update --init --recursive'
    }

    stage('fetch') {
        sh 'swift package fetch'
    }

    stage('lint') {
        checks('Shared/swiftlint.js')
    }

    stage('build') {
        sh 'swift build'
    }

    stage('tests') {
        sh 'swift test'
    }
}

def checks(name) {
    def cred = [$class: 'StringBinding', credentialsId: 'github', variable: 'CHECKS_GITHUB_TOKEN']
    withCredentials([cred]) {
        sh "Checks/Shared/core.js Checks/${name}"
    }
}

node('xcode') {
    ansiColor('xterm') {
        timestamps {
            doit()
        }
    }
}
