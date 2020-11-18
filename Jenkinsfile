#!groovy
// -*- mode: groovy -*-

build('wazuh-docker', 'docker-host') {
  checkoutRepo()
  loadBuildUtils()

  def pipeDefault
  def withWsCache
  runStage('load pipeline') {
    env.JENKINS_LIB = "build_utils/jenkins_lib"
    pipeDefault = load("${env.JENKINS_LIB}/pipeDefault.groovy")
    withWsCache = load("${env.JENKINS_LIB}/withWsCache.groovy")
  }

  pipeDefault() {
    runStage('build wazuh image') {
      sh "cd wazuh && make build_image"
    }
    runStage('build kibana image') {
      sh "cd kibana && make build_image"
    }
    try {
      if (masterlikeBranch()) {
        runStage('push wazuh image') {
          sh "cd wazuh && make push_image"
        }
        runStage('push kibana image') {
          sh "cd kibana && make push_image"
        }
      }
    } finally {
      runStage('rm wazuh local image') {
        sh 'cd wazuh && make rm_local_image'
      }
      runStage('rm kibana local image') {
        sh 'cd kibana && make rm_local_image'
      }
    }
  }
}
