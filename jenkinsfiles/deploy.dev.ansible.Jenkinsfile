#!groovy

pipeline {
    agent any
    environment {
        BUILD_DATE = sh(returnStdout: true, script: "date -u +'%d_%m_%Y_%H_%M_%S'").trim()
    }
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
            steps {
                sh "mkdir artifact"
                sh "mv build/resources/main/application.properties artifact"
                sh "mv build/libs/backend.jar artifact"
                sh "zip -r backend_${BUILD_ID}.zip artifact"
                script {
                    dir('.') {
                    def artifact_name = "backend_${BUILD_ID}"
                    nexusArtifactUploader artifacts: [[artifactId: 'build', file: "${artifact_name}.zip", type: 'zip']],
                        credentialsId: 'jenkins',
                        groupId: 'devops-training',
                        nexusUrl: '${NEXUS_URL}',
                        nexusVersion: 'nexus3',
                        protocol: 'https',
                        repository: '${NEXUS_BACK}',
                        version: "$BUILD_DATE"
                    }
                }    
            }
        }
        stage ('Deploy ansible'){
            environment {
                ARTIFACT_URL = 'https://${NEXUS_URL}/repository/${NEXUS_BACK}/devops-training/build/$BUILD_DATE/build-$BUILD_DATE.zip'
            }
            steps {
               sh "echo ${ARTIFACT_URL}"
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
