#!groovy

pipeline {
    agent any
    tools {
        gradle "gradle"
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
    }
    stages {
        stage('Clone repository') {
            steps {
                git 'https://github.com/nobumori/devops-training-project-backend.git'
            }
        }   
        stage('Build') {
            steps {
                sh "gradle build --no-daemon -x test"
            }
        }
        stage('Sonarqube'){
            when {
                branch 'develop'
            }
            environment {
                scannerHome = tool 'sonarqube_scaner'
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh "gradle --no-daemon -x test sonarqube -Dsonar.projectKey=backend_dev"
                }
            }
        }
        stage("Quality Gate") {
            when {
                branch 'develop'
            }
            steps {
                sleep(5)
                timeout(time: 5, unit: 'MINUTES') {
                    script  {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        stage('Push to Nexus') {
            environment {
                BUILD_DATE = sh(returnStdout: true, script: "date -u +'%d_%m_%Y_%H_%M_%S'").trim()
            }
            steps {
                sh "zip -r backend-${BUILD_ID}.zip build/libs/resources/main/application.properties build/libs/backend.jar"
                script {
                    dir('.') {
                    def artifact_name = "backend-${BUILD_ID}"
                    nexusArtifactUploader artifacts: [[artifactId: 'build', file: "${artifact_name}.zip", type: 'zip']],
                        credentialsId: 'jenkins',
                        groupId: 'devops-training',
                        nexusUrl: '${NEXUS_URL}',
                        nexusVersion: 'nexus3',
                        protocol: 'https',
                        repository: '${NEXUS_BACK}',
                        version: '${BUILD_DATE}'
                    }
                }    
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success{
            echo " ---=== SUCCESS ===---"
        }
        failure{
            echo " ---=== FAILURE ===---"
        }
    }
}
