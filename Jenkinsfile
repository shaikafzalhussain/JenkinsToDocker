pipeline {
    // Defines where the pipeline will run. 'any' means on any available agent.
    agent any

    environment {
        // NOTE: Standard straight double quotes ("") are used here.
        // The original error was caused by using fancy/smart quotes (‘’).
        IMAGE_NAME = "shaikafzalhussain/simple-webpage"
        // The ID of the DockerHub Credentials stored in Jenkins
        DOCKERHUB_CREDENTIALS_ID = 'DockerKey'
    }

    stages {
        stage('Clone Repository') {
            steps {
                // Ensure the branch name is correct (main or master).
                git branch: 'main', url: 'https://github.com/shaikafzalhussain/JenkinsToDocker.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Use the defined environment variable in the shell command
                sh "docker build -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                // *** SECURE CREDENTIALS HANDLING ***
                // The withCredentials block safely injects the username/password
                // into environment variables (dockerUser/dockerPassword) for the block.
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKERHUB_CREDENTIALS_ID, 
                    passwordVariable: 'dockerPassword', 
                    usernameVariable: 'dockerUser'
                )]) {
                    // 1. Login to DockerHub
                    sh "echo ${dockerPassword} | docker login -u ${dockerUser} --password-stdin"
                    
                    // 2. Push the built image
                    sh "docker push ${IMAGE_NAME}:latest"
                    
                    // 3. Optional: Logout immediately after the push is complete
                    sh 'docker logout'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    // Stop and remove old container if running. || true prevents the build from failing if the container doesn't exist.
                    sh 'docker rm -f simple-webpage-container || true'

                    // Run new container from Docker Hub image. Using double quotes for variable interpolation.
                    sh "docker run -d -p 8080:80 --name simple-webpage-container ${IMAGE_NAME}:latest"
                }
            }
        }
    }
    
    // ---
    
    post {
        success {
            echo '✅ Deployment completed successfully! Visit: http://<your-server-ip>:8080'
        }
        failure {
            echo '❌ Build or deployment failed! Check the console output for details.'
        }
        // Always attempt to clean up any login, even if the build fails
        always {
             // This logout is redundant if the one in Push stage is used, but ensures a clean slate.
             sh 'docker logout || true' 
        }
    }
}
