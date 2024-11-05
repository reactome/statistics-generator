// This Jenkinsfile is used by Jenkins to run the BioModels step of Reactome's release.
// It requires that the OrthoinferenceStableIdentifierHistory and AddLinks-Insertion steps have been run successfully before it can be run.

import org.reactome.release.jenkins.utilities.Utilities

// Shared library maintained at 'release-jenkins-utils' repository.
def utils = new Utilities()

pipeline {
    agent any
    
    environment {
		ECR_URL = 'public.ecr.aws/reactome/statistics-generator'
		CONT_NAME = 'stats_generator_container'
    }
    
    stages {
        // This stage pulls the docker image and removes old containers
		stage('Setup: Pull and clean docker environment'){
            steps{
                sh "docker pull ${ECR_URL}:latest"
                sh """
                    if docker ps -a --format '{{.Names}}' | grep -Eq '${CONT_NAME}'; then
                       docker rm -f ${CONT_NAME}
                    fi
                """
            }
        }
      
        stage('generate stats files') {
            steps {
                script {
                    def userInput = input(
                            id: 'userInput', message: 'Enter The release date:?',
                            parameters: [

                                    string(defaultValue: 'None',
                                           description: 'This is the month of the release (e.g. "July")',
                                           name: 'month'),
                                    string(defaultValue: 'None',
                                           description: 'The release year (e.g. "2023") ',
                                           name: 'year'),
                            ])
                  
                    releaseMonth = userInput.month?:''
                    releaseYear = userInput.year?:''
                    
                    sh "sudo rm output/ -rf"
                    sh "mkdir -p output"
                    withCredentials([usernamePassword(credentialsId: 'neo4jUsernamePassword', passwordVariable: 'pass', usernameVariable: 'user')]){
                        sh "docker run -v \$(pwd)/output:/output --net=host --name ${CONT_NAME} ${ECR_URL}:latest /bin/bash -c \'Rscript run.R --user=$user --password=$pass \"${releaseMonth} ${releaseYear}\"\'"
                    }
                }
            }
        }
      
        stage('push stats files to s3') {
            steps {
              script {
                def releaseVersion = utils.getReleaseVersion()
                sh "aws s3 sync ./output s3://download.reactome.org/$releaseVersion/stats/"
              }
            }
        }
    }
}
