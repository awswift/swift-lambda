# Continuous Integration

Swiftda uses a self-hosted Jenkins instance its continuous integration system.
It is hosted at [jenkins.awswift.ge.cx][jenkins-link] and is publicly accessible.

All [pull requests][github-prs] to Swiftda are built and have unit tests and a series of 
checks run against them. The results of these tests are posted to GitHub on their
respective PR threads, but are also available [directly on Jenkins][jenkins-prs].

The CI process that is run against each commit is defined in the Swiftda repo
itself in the [`Jenkinsfile`][jenkinsfile] in the root of the repo. Here you can
also see the battery of checks that each PR is subjected to. Essentially if
[`swiftlint`][swiftlint] reports any style issues, `xcodebuild` has any build
warnings (or errors!) or `swift test` is unhappy the Awswift bot will let you
know via the PR thread on GitHub.

[jenkins-link]: https://jenkins.awswift.ge.cx
[github-prs]: https://github.com/awswift/swiftda/pulls
[jenkins-prs]: https://jenkins.awswift.ge.cx/job/awswift/job/swiftda/view/Pull%20Requests/
[jenkinsfile]: https://github.com/awswift/swiftda/blob/master/Jenkinsfile
[swiftlint]: https://github.com/realm/SwiftLint
