// This Jenkinsfile is used by Jenkins to run the BioModels step of Reactome's release.
// It requires that the OrthoinferenceStableIdentifierHistory and AddLinks-Insertion steps have been run successfully before it can be run.

import org.reactome.release.jenkins.utilities.Utilities

// Shared library maintained at 'release-jenkins-utils' repository.
def utils = new Utilities()

pipeline {
    agent any

    stages {
        stage('pull image') {
            steps {
                script{
                    sh("eval \$(aws ecr get-login --no-include-email --region us-east-1)")
                    docker.withRegistry('https://851227637779.dkr.ecr.us-east-1.amazonaws.com') {
                        docker.image("statistics-generator:latest").pull()
                    }
                }
            }
        }
      
        stage('generate stats files') {
            steps {
                scripts {
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
                  
                    withCredentials([usernamePassword(credentialsId: 'neo4jUsernamePassword', passwordVariable: 'pass', usernameVariable: 'user')]){
                        sh "docker run -v $(pwd)/output:/output --net=host  reactome/statistics-generator:latest /bin/bash -c \'Rscript reactome_release_stats.R --user=$user --password=$pass \"${releaseMonth} ${releaseYear}\"\'"
                    }
                }
            }
        }
      
        stage('push stats files to s3') {
            steps {
              script {
                def releaseVersion = utils.getReleaseVersion()
                sh "aws s3 sync ./output s3://download.reactome.org/$release_version/test_stats/"
              }
            }
        }
    }
}
