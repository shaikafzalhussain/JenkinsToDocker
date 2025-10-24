# Use official NGINX image
FROM nginx:alpine

# Copy our HTML file to NGINX web directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]

