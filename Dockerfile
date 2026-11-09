# Multi-stage build for Godot 4 WebAssembly export
FROM alpine:3.20 AS builder

WORKDIR /opt/godot

RUN apk add --no-cache curl unzip python3 ca-certificates bash

ENV GODOT_VERSION=4.3
ENV GODOT_RELEASE=4.3-stable

# Download headless Godot engine & export templates
RUN curl -sSL https://github.com/godotengine/godot-builds/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_linux.x86_64.zip -o godot.zip && \
    unzip -q godot.zip && \
    mv Godot_v${GODOT_RELEASE}_linux.x86_64 /usr/local/bin/godot && \
    chmod +x /usr/local/bin/godot && \
    rm godot.zip

RUN mkdir -p /root/.local/share/godot/export_templates/${GODOT_VERSION}.stable && \
    curl -sSL https://github.com/godotengine/godot-builds/releases/download/${GODOT_RELEASE}/Godot_v${GODOT_RELEASE}_export_templates.tpz -o templates.zip && \
    python3 -c "\
import zipfile;\
z = zipfile.ZipFile('templates.zip');\
[z.extract(m, '/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable') for m in z.infolist() if m.filename.startswith('templates/') and (setattr(m, 'filename', m.filename[10:]) or True) and m.filename]" && \
    rm templates.zip

WORKDIR /build
COPY . .

# Export project to Web
RUN mkdir -p build/web && \
    godot --headless --export-release "Web" build/web/index.html

# Production Stage: Nginx with COOP & COEP isolation headers
FROM nginx:alpine

COPY --from=builder /build/build/web/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
