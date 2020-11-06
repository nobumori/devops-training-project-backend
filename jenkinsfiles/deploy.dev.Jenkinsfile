#!groovy

pipeline {
    agent any
    parameters {
        string(name: 'commit_id', defaultValue: 'develop', description: 'branch/tag/commit value to deploy')
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
        stage('Test') {
            environment{
                DB_USERNAME="${DB_USERNAME}"
                DB_PASSWORD="${DB_PASSWORD}"
                DB_URL="${DB_URL}"
                DB_PORT="${DB_PORT}"
                DB_NAME="${DB_NAME}"
            }
            steps {
                sh "gradle test"
            }
        }        
        stage('Build') {
            steps {
                sh "gradle build -x test"
            }
        }
        stage('Sonarqube'){
            environment {
                scannerHome = tool 'sonarqube_scaner'
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                     sh "gradle -x test sonarqube -Dsonar.projectKey=backend_dev"
                }
            }
        }
        stage("Quality Gate") {
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
                sh "mv build/libs/*.jar backend-${BUILD_ID}.jar"
                script {
                    dir('.') {
                    def artifact_name = "backend-${BUILD_ID}"
                    nexusArtifactUploader artifacts: [[artifactId: 'build', file: "${artifact_name}.jar", type: 'jar']],
                        credentialsId: 'jenkins',
                        groupId: 'devops-training',
                        nexusUrl: '${NEXUS_URL}',
                        nexusVersion: 'nexus3',
                        protocol: 'https',
                        repository: '${NEXUS_BACK}',
                        version: "${BUILD_DATE}"
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