#!/usr/bin/env groovy

def xcodeVersion() {
  return "Xcode10"
}

properties([
  buildDiscarder(logRotator(numToKeepStr: '30'))
])

try {
  baseStages = baseStages()
  if (isPR()) {
    baseStages << ["Danger": ltDangerStage("Danger", "Danger/Dangerfile")]
    baseStages << ["Apply labels": ltApplyLabelsStage()]
  }

  stage("CI") {
    timeout(time: 30, unit: 'MINUTES') {
      parallel baseStages
    }
  }

  if (currentBuild.previousBuild != null && currentBuild.previousBuild.result != 'SUCCESS') {
    notifyBackToNormal()
  }
} catch(LtStageFailedException e) {
  detectInterruption(e)
  throw e
} catch (e) {
  echo "Failed with error ${e.toString()}"
  detectInterruption(e)
  notifyFailed()
  throw e
}

def maintainersEmails() {
  return "bweiss@lightricks.com"
}

def deviceTestLabels() {
  return ["iOS10", "iOS11"]
}

def simulatorsTestNames() {
  ["iPhone 6s Plus", "iPhone X"]
}

def baseStages() {
  return ["Build for simulators": buildAndTestSimulatorsStage(),
          "Build for devices": buildAndTestDevicesStage(),
          "Static Analysis": staticAnalysisStage()]
}

def notifyFailed() {
  to = isPR() ? "" : maintainersEmails()
  log = currentBuild.rawBuild.getLog(1000).join("<br>")
  stageName = env.STAGE_NAME ?: ""
  emailext(
    to: to,
    subject: "FAILED: Job '${env.JOB_NAME} ${stageName} [${env.BUILD_NUMBER}]'",
    body: """<p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>
    Logs:<br>${log}
    """,
    recipientProviders: [developers()],

    mimeType: 'text/html'
  )
}

def notifyBackToNormal() {
  to = isPR() ? "" : maintainersEmails()
  emailext(
    to: to,
    subject: "Back to normal: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
    body: """<p>Check console output at "<a href="${env.BUILD_URL}">${env.JOB_NAME} [${env.BUILD_NUMBER}]</a>"</p>""",
    recipientProviders: [developers()],
    mimeType: 'text/html'
  )
}

def deviceTestsStages() {
  return deviceTestLabels().collectEntries {
    ["Run tests on device ${it}" : deviceTestStageWithLabel(it)]
  }
}

def simulatorTestsStages() {
  return simulatorsTestNames().collectEntries {
    ["Run tests on simulator ${it}" : simulatorTestStageWithLabel(it)]
  }
}

def staticAnalysisStage() {
	return {
    stage("Static Analysis") {
      node(xcodeVersion()) {
        ws("${workspaceBasePath()}/Repo") {
          try {
            setCommitStatus("PENDING", env.STAGE_NAME, "Build started")
            ltCheckoutStage()
            sh "fastlane static_analysis"
            setCommitStatus("SUCCESS", env.STAGE_NAME, "Build successful")
          } catch(e) {
            setCommitStatus("FAILED", env.STAGE_NAME, "Build failed")
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          } finally {
            archiveArtifacts artifacts: "output/**", allowEmptyArchive: true
          }
        }
      }    
    }
  }
}

def buildAndTestSimulatorsStage() {
  return {
    stage("Build for simulator") {
      node(xcodeVersion()) {
        ws("${workspaceBasePath()}/Repo") {
          try {
            setCommitStatus("PENDING", env.STAGE_NAME, "Build started")
            ltCheckoutStage()
            sh "fastlane build_simulator_test_package package_path:test_package"
            setCommitStatus("SUCCESS", env.STAGE_NAME, "Build successful")
          } catch(e) {
            setCommitStatus("FAILED", env.STAGE_NAME, "Build failed")
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          } finally {
            stash includes: "test_package/**,Fastlane/**,BuildTools/fastlane/**",
                      name: "simulator test package"
            archiveArtifacts artifacts: "output/**", allowEmptyArchive: true
          }
        }
      }
    }
    stage("Test on simulators") {
      parallel simulatorTestsStages()
    }
  }
}

def buildAndTestDevicesStage() {
  return {
    stage("Build for device") {
      node(xcodeVersion()) {
        ws("${workspaceBasePath()}/Repo") {
          try {
            setCommitStatus("PENDING", env.STAGE_NAME, "Build started")
            ltCheckoutStage()
            sh "fastlane build_device_test_package package_path:test_package"
            setCommitStatus("SUCCESS", env.STAGE_NAME, "Build successful")
          } catch(e) {
            setCommitStatus("FAILED", env.STAGE_NAME, "Build failed")
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          } finally {
            stash includes: "test_package/**,Fastlane/**,BuildTools/fastlane/**",
                      name: "device test package"
            archiveArtifacts artifacts: "output/**", allowEmptyArchive: true
          }
        }
      }
    }
    stage("Test on devices") {
      parallel deviceTestsStages()
    }
  }
}

def deviceTestStageWithLabel(label) {
  return {
    stage("Test device ${label}") {
      node(label) {
        ws("${workspaceBasePath()}/Tests") {
          try {
            setCommitStatus("PENDING", env.STAGE_NAME, "Test started")
            cleanWs()
            unstash name: "device test package"
            sh "fastlane run_device_test_package package_path:test_package destination:'id=${env.DEVICE_IDENTIFIER}'"
            setCommitStatus("SUCCESS", env.STAGE_NAME, "Test successful")
          } catch(e) {
            setCommitStatus("FAILED", env.STAGE_NAME, "Test failed")
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          } finally {
            archiveArtifacts artifacts: "output/**", allowEmptyArchive: true
            junit testResults:"output/test_results/*.xml", allowEmptyResults: false
          }
        }
      }
    }
  }
}

def simulatorTestStageWithLabel(simulatorName) {
  return {
    stage("Test simulator ${simulatorName}") {
      node(xcodeVersion()) {
        ws("${workspaceBasePath()}/Tests") {
          try {
            setCommitStatus("PENDING", env.STAGE_NAME, "Test started")
            cleanWs()
            unstash name: "simulator test package"
            sh "fastlane run_simulator_test_package package_path:test_package destination:'platform=iOS Simulator,name=${simulatorName},OS=latest'"
            setCommitStatus("SUCCESS", env.STAGE_NAME, "Test successful")
          } catch(e) {
            setCommitStatus("FAILED", env.STAGE_NAME, "Test failed")
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          } finally {
            archiveArtifacts artifacts: "output/**", allowEmptyArchive: true
            junit testResults:"output/test_results/*.xml", allowEmptyResults: false
          }
        }
      }
    }
  }
}

def ltDangerStage(dangerRepoDir, dangerfile) {
  return  {
    stage("Danger") {
      node(xcodeVersion()) {
        ws("${workspaceBasePath()}/Repo") {
          try {
            ltCheckoutStage()
            withCredentials([[$class: "UsernamePasswordMultiBinding",
                       credentialsId: "4c181906-1270-46d9-abed-e2a853c95d19",
                    usernameVariable: "DANGER_GITHUB_API_USER",
                    passwordVariable: "DANGER_GITHUB_API_TOKEN"]]) {
              sh """
                mkdir -p output
                bundle install --gemfile='${dangerRepoDir}/Gemfile' --path '${WORKSPACE}' --without test --jobs 4
                set -o pipefail && BUNDLE_GEMFILE='${dangerRepoDir}/Gemfile' bundle exec danger --dangerfile='${dangerfile}' --verbose | tee output/danger.log
              """
            }
          } catch(e) {
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          } finally {
            archiveArtifacts artifacts: "output/**", allowEmptyArchive: true
          }
        }
      }
    }
  }
}

def ltApplyLabelsStage() {
  return  {
    stage("Apply labels") {
      node(xcodeVersion()) {
        ws("${workspaceBasePath()}/Repo") {
          try {
            ltCheckoutStage()
            withCredentials([[$class: "UsernamePasswordMultiBinding",
                       credentialsId: "4c181906-1270-46d9-abed-e2a853c95d19",
                    usernameVariable: "DANGER_GITHUB_API_USER",
                    passwordVariable: "DANGER_GITHUB_API_TOKEN"]]) {
              repo = getRepo()
              withEnv(["ghprbGhRepository=" + repo, "ghprbPullId=${env.CHANGE_ID}"]) {
                sh "python BuildTools/ApplyGithubLabels.py"
              }
            }
          } catch(e) {
            detectInterruption(e)
            notifyFailed()
            throw new LtStageFailedException(e)
          }
        }
      }
    }
  }
}

def ltCheckoutStage() {
  stage("Checkout") {
    checkout scm
    sh """
      git reset --hard
      git clean -ffd
      git submodule sync --recursive
      git submodule foreach --recursive git reset --hard
      git submodule update --init --recursive -f --reference $GIT_CACHE -j 16
      git submodule foreach --recursive git clean -ffd
    """
  }
}

def isPR() {
  return (env.BRANCH_NAME ==~ /^PR-\d+$/)
}

def getRepo() {
  tokens = env.CHANGE_URL.tokenize('/')
  org = tokens[tokens.size() - 4]
  repo = tokens[tokens.size() - 3]
  return "${org}/${repo}"
}

def getMultibranchJobName() {
  return JOB_NAME.tokenize('/')[0]
}

def workspaceBasePath() {
  def jobName = getMultibranchJobName()
  path = "workspace/${jobName}"
  if (isPR()) {
    path << "/PullRequests"
  } else {
    path << "/Branches"
  }
  return path
}

def detectInterruption(Exception ex) {
  if ((ex instanceof org.jenkinsci.plugins.workflow.steps.FlowInterruptedException && !ex.message) ||
      (ex instanceof hudson.AbortException && ex.getMessage().contains("script returned exit code 143"))) {
    echo "Stage timed out or aborted"
  }
}

def setCommitStatus(String state, String context, String message) {
  if (!isPR()) {
    return
  }

  step([
    $class: 'GitHubCommitStatusSetter',
    contextSource: [$class: "ManuallyEnteredCommitContextSource", context: context],
    statusBackrefSource: [$class: "ManuallyEnteredBackrefSource", backref: "${env.RUN_DISPLAY_URL}"],
    statusResultSource: [$class: "ConditionalStatusResultSource",
                         results: [[$class: "AnyBuildResult", message: message, state: state]]]
  ])
}

class LtStageFailedException extends Exception {
  LtStageFailedException(e) {
    super(e)
  }
}
