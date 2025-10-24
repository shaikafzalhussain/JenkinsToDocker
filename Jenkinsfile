pipeline {
    // 1. Agent configuration
    agent any
    
    // 2. Environment variables (Docker image specifics)
    environment {
        // Your Docker Hub username (from the image name)
        DOCKER_HUB_USER = "shaikafzalhussain"
        // Your specific repository and image name
        DOCKER_IMAGE_NAME = "simple-webpage" 
        IMAGE_TAG = "latest"
        // The ID of your Username with password credential
        DOCKER_CREDENTIAL_ID = 'DockerKey' 
    }
    
    stages{
        
        stage("Code Clone"){
            steps{
                echo "Code Clone Stage"
                // Your repository URL and branch
                git url: "https://github.com/shaikafzalhussain/JenkinsToDocker.git", branch: "main"
            }
        }
        
        stage("Clear Docker Session"){
            steps{
                // ✅ FIX for 401 Unauthorized pull error: log out to clear stale credentials
                echo "Logging out of Docker to ensure anonymous pull for NGINX base image."
                sh 'docker logout || true' 
            }
        }

        stage("Code Build & Test"){
            steps{
                echo "Code Build Stage"
                // Build the image with a temporary local tag
                sh "docker build -t ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage("Push To DockerHub"){
            steps{
                // 🔑 FIX: Using 'usernamePassword' to match how 'DockerKey' is configured
                withCredentials([usernamePassword(
                    credentialsId: env.DOCKER_CREDENTIAL_ID,
                    usernameVariable: "dockerHubUser",  
                    passwordVariable: "dockerHubPass")]){
                        
                    // 1. Login using the variables extracted from the credential
                    sh 'echo $dockerHubPass | docker login -u $dockerHubUser --password-stdin'
                    
                    // 2. Tag the locally built image with the full remote path
                    sh "docker image tag ${DOCKER_IMAGE_NAME}:${IMAGE_TAG} ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                    
                    // 3. Push the image
                    sh "docker push ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }
        
        stage("Deploy"){
            steps{
                echo "Running Container"
                // Stop/remove previous container before running the new one
                sh 'docker stop simple-webpage || true'
                sh 'docker rm simple-webpage || true'
                sh "docker run -d --name simple-webpage -p 8080:80 ${env.DOCKER_HUB_USER}/${DOCKER_IMAGE_NAME}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            // Log out after push is done for security and to prevent future conflicts
            sh 'docker logout || true' 
        }
        success {
            echo '✅ Pipeline execution successful!'
        }
        failure {
            echo '❌ Pipeline execution failed!'
        }
    }
}
