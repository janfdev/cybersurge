FROM nginx:alpine

# Copy pre-exported WebAssembly files generated from Godot Engine
COPY build/web/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
