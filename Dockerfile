FROM nginx:alpine

# Copy exported Godot web static files
COPY build/web/ /usr/share/nginx/html/

# Copy Nginx server configuration with COOP/COEP headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
