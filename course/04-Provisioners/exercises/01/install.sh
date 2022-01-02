#!/bin/bash

sudo apt update && sudo apt install -y nginx

sudo bash -c 'cat > /var/www/html/index.html' <<EOF
<!DOCTYPE html>
<html>
    <head>
        <title>Example Web Application</title>
    </head>
    <body>
        <h1>Example Web Application</h1>
        <h2>Version: 1.0.0</h2>
    </body>
</html>
EOF

sudo systemctl enable --now nginx
