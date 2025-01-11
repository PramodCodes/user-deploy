// Jenkinsfile (Declarative Pipeline) 
pipeline{
    agent {
        // run on the AGENT-1 node
        node {
            label 'AGENT-1'
        }
    }
    // parameters section, this section is used to define the parameters that can be used in the pipeline
    // define the environment variables canbe accesed globally ,the following are additional to existing environment variables
    // we use ansiColor plugin to print the logs in color
    options {
        ansiColor('xterm')
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
    }
    // we need to get version from the application for this we use pipeline, for this we will use pipeline utilities plugin
    // this can be used across pipeline
    // environment {
    //     packageVersion = ''
    //     nexusURL = 'nexus.pka.in.net:8081'
    // }
    
    parameters {
        string(name: 'version', defaultValue: '', description: 'what is the artifact version?')
        string(name: 'environment', defaultValue: '', description: 'what is the Environment?')
        booleanParam(name: 'Destroy', defaultValue: 'false', description: 'Do you want to destroy environment?')
        booleanParam(name: 'Create', defaultValue: 'true', description: 'Do you want to create environment?')
    }
    
    //build stages
    stages {
        stage('Print Version') {
            steps {
                sh """
                    echo "current build version is ${params.version}"
                    echo "Environment is ${params.environment}"
                """
            }
        }
// the following will init the backend config with the env directory and reconfigures the environment
        stage('Terraform Init') {
            steps {
                sh """
                   echo 'Terraform Init'
                   pwd
                   cd terraform
                   pwd
                    terraform init --backend-config=${params.environment}/backend.tf -reconfigure
                """
            }
        }
        stage('Terraform plan') {
            steps {
                sh """
                   echo 'Terraform plan'
                   pwd
                   cd terraform
                   pwd
                   terraform plan -var-file=${params.environment}/${params.environment}.tfvars -var="app_version=${params.version}"
                """
            }
        }
        stage('Terraform apply') {
            when {
                expression{
                    params.Create == true
                }
            }
            steps {
                sh """
                   echo 'Terraform apply'
                   pwd
                   cd terraform
                   pwd
                   terraform apply -var-file=${params.environment}/${params.environment}.tfvars -var="app_version=${params.version}" -auto-approve
                """
            }
        }
        stage('Destory Environment') {
            when {
                expression{
                    params.Destroy == true
                }
            }
            steps {
                sh """
                   echo 'Terraform destroy'
                   pwd
                   cd terraform
                   pwd
                   terraform destroy -var-file=${params.environment}/${params.environment}.tfvars -var="app_version=${params.version}" -auto-approve
                   echo 'destroyed user deployment'
                """
            }
        }
    }

    // post section
    post {
        always {
            echo 'This will always run irrespective of status of the pipeline'
            // you need to delete workspace after the build because we are using the same workspace for all the builds
            deleteDir()
        }
        failure {
            echo 'This will run only if the pipeline is failed, We use thsi for alerting the team' 
        }
        success {
            echo 'This will run only if the pipeline is successful'
        }
    }
}
