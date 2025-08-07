# Use nginx:alpine for lightweight static file serving
FROM nginx:alpine

# Set maintainer
LABEL maintainer="AutoMax DevOps Team <devops@automax.com>"
LABEL version="1.0.0"
LABEL description="AutoMax Car Dealership Static Website"

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy static website files
COPY index.html /usr/share/nginx/html/
COPY static/styles.css /usr/share/nginx/html/
COPY static/script.js /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set proper permissions for existing nginx user
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Switch to non-root user (nginx user already exists in base image)
USER nginx

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
