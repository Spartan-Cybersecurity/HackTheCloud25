#!/bin/bash

# Update system
yum update -y

# Install required packages
yum install -y httpd php php-curl

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Set environment variables with bucket names for realistic discovery via metadata service
# These will be available via the EC2 metadata service at:
# http://169.254.169.254/latest/user-data
export MEDICLOUDX_CREDENTIALS_BUCKET="${credentials_bucket_name}"
export MEDICLOUDX_PATIENT_DATA_BUCKET="${flag_bucket_name}"

# Also add them to a configuration file that could be discovered
cat > /opt/medicloudx/config.env << EOF
# MediCloudX Health Platform Configuration
# Auto-generated during instance initialization
MEDICLOUDX_CREDENTIALS_BUCKET=${credentials_bucket_name}
MEDICLOUDX_PATIENT_DATA_BUCKET=${flag_bucket_name}
MEDICLOUDX_VERSION=2.1.3
MEDICLOUDX_ENVIRONMENT=production
MEDICLOUDX_REGION=us-east-1
EOF

# Make the config directory and file accessible
mkdir -p /opt/medicloudx
chmod 755 /opt/medicloudx
chmod 644 /opt/medicloudx/config.env

# Create the vulnerable web application
cat > /var/www/html/index.php << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediCloudX Health - Portal de Análisis de Datos</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', sans-serif;
            background: linear-gradient(135deg, #0a1628 0%, #1e3a8a 50%, #3b82f6 100%);
            color: white;
            min-height: 100vh;
        }
        
        .navbar {
            background: rgba(10, 22, 40, 0.9);
            backdrop-filter: blur(10px);
            padding: 20px 5%;
            border-bottom: 1px solid rgba(59, 130, 246, 0.2);
        }
        
        .nav-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .logo {
            display: flex;
            align-items: center;
            font-size: 24px;
            font-weight: 700;
            color: #60a5fa;
        }
        
        .logo::before {
            content: "🏥";
            margin-right: 10px;
            font-size: 28px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 40px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #60a5fa, #a78bfa);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .header p {
            color: rgba(255, 255, 255, 0.8);
            font-size: 1.1rem;
        }
        
        .tool-section {
            background: rgba(59, 130, 246, 0.1);
            padding: 30px;
            border-radius: 15px;
            border: 1px solid rgba(59, 130, 246, 0.2);
            backdrop-filter: blur(10px);
            margin-bottom: 30px;
        }
        
        .tool-section h2 {
            color: #60a5fa;
            margin-bottom: 20px;
            font-size: 1.5rem;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: rgba(255, 255, 255, 0.9);
            font-weight: 500;
        }
        
        .form-group input, .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid rgba(59, 130, 246, 0.3);
            border-radius: 8px;
            background: rgba(10, 22, 40, 0.5);
            color: white;
            font-size: 14px;
        }
        
        .form-group input:focus, .form-group textarea:focus {
            outline: none;
            border-color: #60a5fa;
            box-shadow: 0 0 0 2px rgba(96, 165, 250, 0.2);
        }
        
        .btn {
            background: linear-gradient(135deg, #3b82f6, #1d4ed8);
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-block;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(59, 130, 246, 0.3);
        }
        
        .result-box {
            background: rgba(10, 22, 40, 0.7);
            border: 1px solid rgba(59, 130, 246, 0.3);
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
            font-family: 'Courier New', monospace;
            white-space: pre-wrap;
            max-height: 400px;
            overflow-y: auto;
        }
        
        .warning {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid rgba(239, 68, 68, 0.3);
            color: #fca5a5;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .info {
            background: rgba(34, 197, 94, 0.1);
            border: 1px solid rgba(34, 197, 94, 0.3);
            color: #86efac;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-content">
            <div class="logo">MediCloudX Health - Portal de Análisis</div>
            <div style="color: rgba(255, 255, 255, 0.6); font-size: 14px;">
                Sistema Interno v2.1.3 | Servidor: <?php echo gethostname(); ?>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="header">
            <h1>Portal de Análisis de Datos Médicos</h1>
            <p>Herramientas internas para análisis de datos de pacientes y conectividad con servicios externos</p>
        </div>
        
        <div class="info">
            <strong>🔒 Acceso Autorizado:</strong> Este sistema está destinado únicamente para personal autorizado de MediCloudX Health. 
            Todas las actividades son monitoreadas y registradas para cumplimiento con HIPAA.
        </div>
        
        <div class="tool-section">
            <h2>📊 Verificador de Conectividad de Servicios Externos</h2>
            <p style="color: rgba(255, 255, 255, 0.7); margin-bottom: 20px;">
                Esta herramienta permite verificar la conectividad con servicios externos de análisis de datos médicos, 
                APIs de laboratorios y sistemas de terceros integrados con nuestra plataforma.
            </p>
            
            <form method="GET" action="">
                <div class="form-group">
                    <label for="url">URL del Servicio a Verificar:</label>
                    <input type="text" id="url" name="url" placeholder="https://api.laboratorio-externo.com/health-check" 
                           value="<?php echo isset($_GET['url']) ? htmlspecialchars($_GET['url']) : ''; ?>">
                </div>
                <button type="submit" class="btn">🔍 Verificar Conectividad</button>
            </form>
            
            <?php
            if (isset($_GET['url']) && !empty($_GET['url'])) {
                $url = $_GET['url'];
                echo '<div class="result-box">';
                echo "Verificando conectividad con: " . htmlspecialchars($url) . "\n";
                echo "Timestamp: " . date('Y-m-d H:i:s') . "\n";
                echo "----------------------------------------\n\n";
                
                # Connectivity checker - validates external service endpoints
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $url);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                curl_setopt($ch, CURLOPT_USERAGENT, 'MediCloudX-HealthChecker/2.1.3');
                
                $response = curl_exec($ch);
                $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $error = curl_error($ch);
                curl_close($ch);
                
                if ($error) {
                    echo "❌ Error de conectividad: " . $error . "\n";
                } else {
                    echo "✅ Código de respuesta HTTP: " . $http_code . "\n";
                    echo "📄 Respuesta del servicio:\n\n";
                    echo htmlspecialchars($response);
                }
                
                echo '</div>';
            }
            ?>
        </div>
        
        <div class="tool-section">
            <h2>📈 Estado del Sistema</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px;">
                <div style="background: rgba(34, 197, 94, 0.1); padding: 20px; border-radius: 10px; border: 1px solid rgba(34, 197, 94, 0.3);">
                    <h3 style="color: #86efac; margin-bottom: 10px;">🟢 Base de Datos</h3>
                    <p>Conectado - 1,247 pacientes activos</p>
                </div>
                <div style="background: rgba(34, 197, 94, 0.1); padding: 20px; border-radius: 10px; border: 1px solid rgba(34, 197, 94, 0.3);">
                    <h3 style="color: #86efac; margin-bottom: 10px;">🟢 API Gateway</h3>
                    <p>Operacional - 99.7% uptime</p>
                </div>
                <div style="background: rgba(251, 191, 36, 0.1); padding: 20px; border-radius: 10px; border: 1px solid rgba(251, 191, 36, 0.3);">
                    <h3 style="color: #fcd34d; margin-bottom: 10px;">🟡 Análisis ML</h3>
                    <p>Procesando - Cola: 23 trabajos</p>
                </div>
                <div style="background: rgba(34, 197, 94, 0.1); padding: 20px; border-radius: 10px; border: 1px solid rgba(34, 197, 94, 0.3);">
                    <h3 style="color: #86efac; margin-bottom: 10px;">🟢 Storage S3</h3>
                    <p>Disponible - 2.3TB utilizados</p>
                </div>
            </div>
        </div>
        
        <div class="warning">
            <strong>⚠️ Aviso de Seguridad:</strong> Si detecta actividad sospechosa o problemas de conectividad, 
            contacte inmediatamente al equipo de DevOps en devops@medicloudx.com o al administrador del sistema.
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.php
chmod 644 /var/www/html/index.php

# Create a simple health check endpoint
cat > /var/www/html/health.php << 'EOF'
<?php
header('Content-Type: application/json');
echo json_encode([
    'status' => 'healthy',
    'timestamp' => date('c'),
    'server' => gethostname(),
    'service' => 'MediCloudX Health Portal'
]);
?>
EOF

# Restart Apache to ensure everything is loaded
systemctl restart httpd

# Create a hint file that might be discovered during reconnaissance
cat > /var/www/html/robots.txt << 'EOF'
User-agent: *
Disallow: /admin/
Disallow: /config/
Disallow: /backup/

# Internal note: Configuration files stored in /opt/medicloudx/
# Remember to rotate credentials quarterly - DevOps Team
EOF

# Log the completion
echo "$(date): MediCloudX Health Portal setup completed" >> /var/log/user-data.log
echo "$(date): Bucket configuration: credentials=${credentials_bucket_name}, patient-data=${flag_bucket_name}" >> /var/log/user-data.log
