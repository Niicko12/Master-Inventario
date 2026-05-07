# Especificación Técnica — Reportes, Documentos e Integraciones

---
name: spec-reportes-documentos-integraciones
modules: reportes, documentos, integraciones
status: active
created: 2026-04-24T21:19:11Z
updated: 2026-04-24T21:19:11Z
---

## Índice

1. [Módulo Reportes](#1-módulo-reportes)
2. [Módulo Documentos](#2-módulo-documentos)
3. [Módulo Gráficas](#3-módulo-gráficas)
4. [Módulo Integraciones Externas](#4-módulo-integraciones-externas)
5. [Módulo Soporte y Mantenimiento](#5-módulo-soporte-y-mantenimiento)
6. [Módulo Administración de Usuarios](#6-módulo-administración-de-usuarios)
7. [Módulo Configuración del Sistema](#7-módulo-configuración-del-sistema)
8. [Quality Requirements Transversales](#8-quality-requirements-transversales)

---

## 1. Módulo Reportes

### 1.1 Visión General

El módulo de Reportes genera documentos en PDF y Excel con datos del sistema para análisis y auditoría. Accesible solo para Administrador.

### 1.2 Archivos

| Archivo | Responsabilidad |
|---------|----------------|
| `reportes.php` | Interfaz principal de reportes |
| `reporte_ventas_pdf.php` | Genera PDF de ventas |
| `descargar_reporte.php` | Descarga archivo de reportes guardado |
| `eliminar_reporte.php` | Elimina reporte del servidor |
| `plantilla_reporte.php` | Plantilla base de reportes |

### 1.3 Tipos de reportes disponibles

| Tipo | Formato | Datos incluidos |
|------|---------|----------------|
| Reporte de Ventas | PDF + Excel | Ventas por período, cliente, producto |
| Reporte de Inventario | PDF + Excel | Stock actual, alertas de stock bajo |
| Reporte de Compras | PDF + Excel | Compras por período, proveedor |
| Reporte de Movimientos | PDF | Entradas y salidas de inventario |
| Reporte de Usuarios | PDF | Actividad de usuarios |

### 1.4 Flujo de generación de reportes

```
1. Admin selecciona tipo de reporte y rango de fechas
2. POST a reportes.php con parámetros
3. PHP ejecuta query específica del tipo de reporte
4. PHP instancia FPDF o PhpSpreadsheet
5. Genera el documento con los datos
6. Opción A: Descarga directa al navegador
7. Opción B: Guarda en reportes/ y muestra enlace de descarga
```

### 1.5 Generación de PDF con FPDF

```php
require_once 'fpdf/fpdf.php';

class ReporteVentas extends FPDF {
    private string $titulo;
    private string $periodo;
    
    public function __construct(string $titulo, string $periodo) {
        parent::__construct('L', 'mm', 'A4'); // Landscape
        $this->titulo = $titulo;
        $this->periodo = $periodo;
    }
    
    // Header de cada página
    function Header() {
        // Logo
        if (file_exists('logo.png')) {
            $this->Image('logo.png', 10, 8, 25);
        }
        $this->SetFont('Arial', 'B', 16);
        $this->Cell(0, 10, $this->titulo, 0, 1, 'C');
        $this->SetFont('Arial', '', 10);
        $this->Cell(0, 6, 'Período: ' . $this->periodo, 0, 1, 'C');
        $this->Ln(4);
    }
    
    // Footer de cada página
    function Footer() {
        $this->SetY(-15);
        $this->SetFont('Arial', 'I', 8);
        $this->Cell(0, 10, 'Página ' . $this->PageNo() . '/{nb}', 0, 0, 'C');
    }
    
    public function tablaVentas(array $ventas): void {
        // Encabezados de tabla
        $this->SetFillColor(52, 73, 94);
        $this->SetTextColor(255, 255, 255);
        $this->SetFont('Arial', 'B', 10);
        
        $this->Cell(20,  8, 'ID',        1, 0, 'C', true);
        $this->Cell(60,  8, 'Cliente',   1, 0, 'C', true);
        $this->Cell(40,  8, 'Fecha',     1, 0, 'C', true);
        $this->Cell(40,  8, 'Producto',  1, 0, 'C', true);
        $this->Cell(25,  8, 'Cantidad',  1, 0, 'C', true);
        $this->Cell(35,  8, 'Monto',     1, 0, 'C', true);
        $this->Cell(35,  8, 'Estado',    1, 1, 'C', true);
        
        // Datos
        $this->SetFillColor(255, 255, 255);
        $this->SetTextColor(0, 0, 0);
        $this->SetFont('Arial', '', 9);
        
        $total = 0;
        foreach ($ventas as $v) {
            $fill = ($v['estado'] === 'Completada');
            $this->Cell(20,  7, $v['id_venta'],        1, 0, 'C', $fill);
            $this->Cell(60,  7, $v['cliente'],          1, 0, 'L', $fill);
            $this->Cell(40,  7, $v['fecha_venta'],      1, 0, 'C', $fill);
            $this->Cell(40,  7, $v['nombre_producto'],  1, 0, 'L', $fill);
            $this->Cell(25,  7, $v['cantidad_vendida'], 1, 0, 'R', $fill);
            $this->Cell(35,  7, '$' . number_format($v['monto_total'], 2), 1, 0, 'R', $fill);
            $this->Cell(35,  7, $v['estado'],           1, 1, 'C', $fill);
            $total += floatval($v['monto_total']);
        }
        
        // Total
        $this->SetFont('Arial', 'B', 10);
        $this->Cell(185, 8, 'TOTAL', 1, 0, 'R');
        $this->Cell(35,  8, '$' . number_format($total, 2), 1, 1, 'R');
    }
}

// Uso
function generateSalesReport(array $ventas, string $desde, string $hasta): void {
    $pdf = new ReporteVentas('Reporte de Ventas', "{$desde} al {$hasta}");
    $pdf->AliasNbPages();
    $pdf->AddPage();
    $pdf->tablaVentas($ventas);
    
    $filename = 'reporte_ventas_' . date('Ymd_His') . '.pdf';
    $pdf->Output('D', $filename); // D = download directo
}
```

### 1.6 Generación de Excel con PhpSpreadsheet

```php
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;

function generateInventarioExcel(array $productos): void {
    $spreadsheet = new Spreadsheet();
    $sheet = $spreadsheet->getActiveSheet();
    $sheet->setTitle('Inventario');
    
    // Estilo de encabezados
    $headerStyle = [
        'font'      => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
        'fill'      => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '34495E']],
        'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
    ];
    
    // Headers
    $headers = ['ID', 'Producto', 'Stock Actual', 'Stock Mínimo', 'Estado', 'Precio', 'Última Actualización'];
    foreach ($headers as $col => $header) {
        $cell = $sheet->getCellByColumnAndRow($col + 1, 1);
        $cell->setValue($header);
        $cell->getStyle()->applyFromArray($headerStyle);
    }
    
    // Auto-ancho de columnas
    foreach (range('A', 'G') as $col) {
        $sheet->getColumnDimension($col)->setAutoSize(true);
    }
    
    // Datos con formato condicional de stock
    foreach ($productos as $i => $prod) {
        $row = $i + 2;
        $estado = $prod['cantidad_disponible'] == 0 ? 'Sin Stock' 
               : ($prod['cantidad_disponible'] <= $prod['stock_minimo'] ? 'Stock Bajo' : 'Normal');
        
        $sheet->setCellValueByColumnAndRow(1, $row, $prod['id_producto']);
        $sheet->setCellValueByColumnAndRow(2, $row, $prod['nombre_producto']);
        $sheet->setCellValueByColumnAndRow(3, $row, $prod['cantidad_disponible']);
        $sheet->setCellValueByColumnAndRow(4, $row, $prod['stock_minimo']);
        $sheet->setCellValueByColumnAndRow(5, $row, $estado);
        $sheet->setCellValueByColumnAndRow(6, $row, $prod['precio_unitario']);
        $sheet->setCellValueByColumnAndRow(7, $row, $prod['fecha_ultima_actualizacion']);
        
        // Color de fila según estado
        if ($estado === 'Sin Stock') {
            $sheet->getStyle("A{$row}:G{$row}")->getFill()
                ->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('FFCCCC');
        } elseif ($estado === 'Stock Bajo') {
            $sheet->getStyle("A{$row}:G{$row}")->getFill()
                ->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('FFF3CD');
        }
    }
    
    header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    header('Content-Disposition: attachment;filename="inventario_' . date('Ymd') . '.xlsx"');
    header('Cache-Control: max-age=0');
    
    $writer = new Xlsx($spreadsheet);
    $writer->save('php://output');
}
```

### 1.7 Reglas de negocio de reportes

```
RN-REP-001: Solo Administrador tiene acceso al módulo de Reportes
RN-REP-002: Los reportes en PDF se guardan opcionalmente en reportes/ con nombre único (timestamp)
RN-REP-003: Los reportes de más de 30 días de antigüedad pueden eliminarse automáticamente
RN-REP-004: El rango de fechas máximo para un reporte es 1 año
RN-REP-005: Los reportes deben incluir: logo, período, fecha de generación, usuario que generó
```

---

## 2. Módulo Documentos

### 2.1 Visión General

Repositorio de archivos del negocio (facturas, contratos, informes) con vinculación a entidades del sistema (ventas, inventario, etc.).

### 2.2 Archivos

| Archivo | Responsabilidad |
|---------|----------------|
| `documentos.php` | Listado + upload de documentos |
| `editar_documento.php` | Edición de metadata del documento |

### 2.3 Casos de uso

**CU-DOC-001: Subir documento**
```
1. Usuario selecciona tipo de documento, descripción, versión, fecha
2. Selecciona archivo para subir (max 5MB)
3. Opcionalmente vincula a una entidad (tabla + ID)
4. POST a documentos.php
5. PHP valida tipo MIME, tamaño, extensión
6. PHP mueve archivo a uploads/ con nombre único
7. INSERT en Documentos
8. Si hay vinculación: INSERT en Documentos_Registros
9. Mostrar confirmación
```

**CU-DOC-002: Descargar documento**
```
1. Usuario hace clic en "Descargar"
2. GET a endpoint de descarga con id_documento
3. PHP verifica que el archivo existe en uploads/
4. PHP envía headers de descarga
5. PHP lee y envía el archivo
```

**CU-DOC-003: Editar metadata**
```
1. Usuario accede a editar_documento.php?id={id}
2. Modifica: tipo, descripción, versión, fecha
3. POST
4. PHP actualiza registro en Documentos (sin cambiar el archivo)
```

**CU-DOC-004: Vincular documento a entidad**
```
1. Al crear o editar documento, seleccionar tabla destino y ID
2. INSERT en Documentos_Registros (id_documento, tabla, registro_id)
3. El documento puede vincularse a: Ventas, Inventario, Compras, Proveedores
```

### 2.4 Validaciones de upload

```php
function validateFileUpload(array $file): array {
    $errors = [];
    
    // Tipos permitidos (validar MIME, no extensión)
    $allowed_mimes = [
        'application/pdf',
        'text/plain',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ];
    
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = $finfo->file($file['tmp_name']);
    
    if (!in_array($mime, $allowed_mimes)) {
        $errors[] = "Tipo de archivo no permitido: {$mime}";
    }
    
    // Tamaño máximo: 5MB
    if ($file['size'] > 5 * 1024 * 1024) {
        $errors[] = "El archivo no puede superar 5MB";
    }
    
    // Verificar que no hay errores del servidor
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errors[] = "Error en el upload: código {$file['error']}";
    }
    
    return $errors;
}
```

### 2.5 Manejo seguro de archivos subidos

```php
function saveUploadedFile(array $file): string {
    $upload_dir = __DIR__ . '/uploads/';
    
    // Generar nombre único para evitar colisiones y path traversal
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $safe_name = uniqid('doc_', true) . '.' . strtolower($extension);
    $destination = $upload_dir . $safe_name;
    
    if (!move_uploaded_file($file['tmp_name'], $destination)) {
        throw new RuntimeException("Error al guardar el archivo");
    }
    
    return 'uploads/' . $safe_name;
}
```

### 2.6 Reglas de negocio

```
RN-DOC-001: Solo Administrador y Empleado pueden subir documentos
RN-DOC-002: Los archivos se renombran con uniqid() al subir para evitar colisiones
RN-DOC-003: El archivo original no se elimina al editar la metadata
RN-DOC-004: Al eliminar un documento: eliminar registro + archivo físico en uploads/
RN-DOC-005: Tipos permitidos: PDF, TXT, DOC, DOCX, XLS, XLSX (máx 5MB)
RN-DOC-006: Los documentos pueden vincularse a múltiples entidades
```

---

## 3. Módulo Gráficas

### 3.1 Visión General

Visualizaciones analíticas de los datos del sistema, accesible solo para Administrador.

### 3.2 Datos para gráficas

```php
// Ventas por mes (últimos 12 meses)
$stmt = $conn->prepare(
    "SELECT DATE_FORMAT(fecha_venta, '%Y-%m') AS mes,
            SUM(monto_total) AS total,
            COUNT(*) AS cantidad
     FROM Ventas
     WHERE fecha_venta >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
     GROUP BY mes ORDER BY mes"
);

// Productos más vendidos (top 10)
$stmt = $conn->prepare(
    "SELECT I.nombre_producto,
            SUM(DV.cantidad_vendida) AS total_vendido
     FROM Detalle_Ventas DV
     JOIN Inventario I ON DV.id_producto = I.id_producto
     GROUP BY DV.id_producto
     ORDER BY total_vendido DESC LIMIT 10"
);

// Estado del inventario (distribución por niveles de stock)
$stmt = $conn->prepare(
    "SELECT 
        SUM(CASE WHEN cantidad_disponible = 0 THEN 1 ELSE 0 END) AS sin_stock,
        SUM(CASE WHEN cantidad_disponible > 0 AND cantidad_disponible <= stock_minimo THEN 1 ELSE 0 END) AS stock_bajo,
        SUM(CASE WHEN cantidad_disponible > stock_minimo THEN 1 ELSE 0 END) AS normal
     FROM Inventario WHERE activo = 1"
);

// Compras vs Ventas por mes
$stmt = $conn->prepare(
    "SELECT m.mes,
            COALESCE(v.total_ventas, 0) AS ventas,
            COALESCE(c.total_compras, 0) AS compras
     FROM (
        SELECT DATE_FORMAT(fecha_venta, '%Y-%m') AS mes FROM Ventas
        UNION
        SELECT DATE_FORMAT(fecha_compra, '%Y-%m') FROM Compras
     ) m
     LEFT JOIN (
        SELECT DATE_FORMAT(fecha_venta, '%Y-%m') AS mes, SUM(monto_total) AS total_ventas
        FROM Ventas GROUP BY mes
     ) v ON m.mes = v.mes
     LEFT JOIN (
        SELECT DATE_FORMAT(fecha_compra, '%Y-%m') AS mes, SUM(monto_total) AS total_compras
        FROM Compras GROUP BY mes
     ) c ON m.mes = c.mes
     ORDER BY m.mes DESC LIMIT 12"
);
```

### 3.3 Inyección de datos PHP → JavaScript

```php
// Patrón seguro para pasar datos PHP a Chart.js
$ventas_data = $conn->query("...")->fetch_all(MYSQLI_ASSOC);
$labels = array_column($ventas_data, 'mes');
$totales = array_column($ventas_data, 'total');
?>
<script>
const ventasLabels = <?php echo json_encode($labels, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP); ?>;
const ventasTotales = <?php echo json_encode($totales, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_AMP); ?>;

new Chart(document.getElementById('ventas-chart'), {
    type: 'bar',
    data: {
        labels: ventasLabels,
        datasets: [{
            label: 'Ventas Mensuales',
            data: ventasTotales,
            backgroundColor: 'rgba(52, 73, 94, 0.7)',
        }]
    },
    options: { responsive: true, scales: { y: { beginAtZero: true } } }
});
</script>
```

---

## 4. Módulo Integraciones Externas

### 4.1 Visión General

Permite importar datos al sistema desde archivos CSV con un flujo de mapeo interactivo de columnas.

### 4.2 Flujo completo de importación CSV

```
Paso 1: Usuario selecciona tabla destino + sube CSV
    ↓
Paso 2: procesar_datos_api.php parsea el CSV y retorna las columnas detectadas
    ↓
Paso 3: Modal de mapeo: usuario asigna cada columna CSV a columna de BD
    ↓
Paso 4: procesar_mapeo_api.php valida, transforma e inserta los datos
    ↓
Paso 5: Reporte de resultados (X éxitos, Y errores)
```

### 4.3 Procesamiento de CSV

```php
// procesar_datos_api.php — detectar columnas del CSV
function parseCsvHeaders(string $filepath): array {
    $headers = [];
    if (($handle = fopen($filepath, 'r')) !== false) {
        $headers = fgetcsv($handle, 1000, ',');
        fclose($handle);
    }
    return $headers;
}

function parseCsvData(string $filepath, int $max_rows = 1000): array {
    $rows = [];
    if (($handle = fopen($filepath, 'r')) !== false) {
        $headers = fgetcsv($handle, 1000, ',');
        $row_count = 0;
        
        while (($data = fgetcsv($handle, 1000, ',')) !== false && $row_count < $max_rows) {
            $rows[] = array_combine($headers, $data);
            $row_count++;
        }
        fclose($handle);
    }
    return $rows;
}
```

### 4.4 Procesamiento del mapeo

```php
// procesar_mapeo_api.php — insertar datos mapeados
function insertMappedData(
    mysqli $conn, 
    string $tabla_destino,
    array $csv_rows,
    array $mapeo  // ['csv_col' => 'db_col', ...]
): array {
    $results = ['success' => 0, 'errors' => []];
    
    // Validar tabla destino (whitelist)
    $allowed_tables = ['Inventario', 'Proveedores', 'Usuarios'];
    if (!in_array($tabla_destino, $allowed_tables)) {
        throw new InvalidArgumentException("Tabla no permitida: {$tabla_destino}");
    }
    
    foreach ($csv_rows as $i => $csv_row) {
        try {
            // Construir la fila mapeada
            $mapped_row = [];
            foreach ($mapeo as $csv_col => $db_col) {
                if (!empty($db_col) && isset($csv_row[$csv_col])) {
                    $mapped_row[$db_col] = trim($csv_row[$csv_col]);
                }
            }
            
            if (empty($mapped_row)) continue;
            
            // Construir query dinámico de forma segura
            $columns = implode(', ', array_keys($mapped_row));
            $placeholders = implode(', ', array_fill(0, count($mapped_row), '?'));
            
            $stmt = $conn->prepare(
                "INSERT INTO {$tabla_destino} ({$columns}) VALUES ({$placeholders})"
            );
            
            $types = str_repeat('s', count($mapped_row));
            $values = array_values($mapped_row);
            $stmt->bind_param($types, ...$values);
            $stmt->execute();
            $stmt->close();
            
            $results['success']++;
            
        } catch (mysqli_sql_exception $e) {
            $results['errors'][] = "Fila {$i}: " . $e->getMessage();
        }
    }
    
    return $results;
}
```

### 4.5 Validaciones de seguridad para importación

```php
// Validar que las columnas del mapeo existen en la tabla
function validateColumnMapping(mysqli $conn, string $tabla, array $db_columns): bool {
    $result = $conn->query("SHOW COLUMNS FROM `{$tabla}`");
    $valid_columns = [];
    while ($row = $result->fetch_assoc()) {
        $valid_columns[] = $row['Field'];
    }
    
    foreach ($db_columns as $col) {
        if (!empty($col) && !in_array($col, $valid_columns)) {
            return false;
        }
    }
    return true;
}
```

### 4.6 Reglas de negocio

```
RN-INT-001: Solo Administrador puede usar integraciones externas
RN-INT-002: Tablas permitidas para importación: whitelist estricta
RN-INT-003: CSV máximo 5MB y 1000 filas por importación
RN-INT-004: Errores de inserción se reportan por fila, sin detener el proceso
RN-INT-005: Los archivos CSV se eliminan del servidor tras el procesamiento
RN-INT-006: El mapeo de columnas no permite modificar columnas del sistema (id_*, created_at)
```

---

## 5. Módulo Soporte y Mantenimiento

### 5.1 Visión General

Módulo para registrar y gestionar tickets de soporte técnico e incidencias del sistema.

### 5.2 Funcionalidades

- Registro de nuevos tickets de soporte
- Clasificación por tipo (Bug, Mejora, Consulta, Urgente)
- Seguimiento de estado del ticket
- Historial de incidencias resueltas
- Notas internas del equipo técnico

### 5.3 Estados de un ticket

```
[Abierto] → [En Progreso] → [Resuelto] → [Cerrado]
              ↑                            ↓
              └────────────────────────────┘
                    (reapertura)
```

### 5.4 Schema de BD (pendiente crear)

```sql
CREATE TABLE Tickets_Soporte (
  id_ticket     INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario    INT NOT NULL,
  titulo        VARCHAR(200) NOT NULL,
  descripcion   TEXT NOT NULL,
  tipo          ENUM('Bug','Mejora','Consulta','Urgente') DEFAULT 'Consulta',
  estado        ENUM('Abierto','En Progreso','Resuelto','Cerrado') DEFAULT 'Abierto',
  prioridad     ENUM('Baja','Media','Alta','Crítica') DEFAULT 'Media',
  fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion DATETIME,
  notas_internas TEXT,
  FOREIGN KEY (id_usuario) REFERENCES Usuarios(id_usuario)
) ENGINE=InnoDB;
```

---

## 6. Módulo Administración de Usuarios

### 6.1 Funcionalidades

- Listado de todos los usuarios del sistema
- Crear usuario con validación de email único
- Editar datos de usuario (nombre, rol, teléfono)
- Cambiar estado activo/inactivo
- Reset de contraseña forzado por Admin
- Ver historial de actividad del usuario

### 6.2 Operaciones de BD

```php
// Listar todos los usuarios
$stmt = $conn->prepare(
    "SELECT id_usuario, nombre, correo_electronico, rol, estado, telefono, fecha_creacion
     FROM Usuarios ORDER BY fecha_creacion DESC"
);

// Cambiar estado de usuario
$stmt = $conn->prepare(
    "UPDATE Usuarios SET estado = ? WHERE id_usuario = ?"
);
$stmt->bind_param("si", $nuevo_estado, $id_usuario);

// Reset de contraseña por Admin
function adminResetPassword(mysqli $conn, int $user_id, string $new_password): void {
    $hash = password_hash($new_password, PASSWORD_BCRYPT, ['cost' => 12]);
    $stmt = $conn->prepare("UPDATE Usuarios SET contrasena = ? WHERE id_usuario = ?");
    $stmt->bind_param("si", $hash, $user_id);
    $stmt->execute();
    $stmt->close();
}
```

### 6.3 Reglas de negocio

```
RN-ADM-001: Solo Administrador puede gestionar usuarios
RN-ADM-002: Un Administrador no puede desactivarse a sí mismo
RN-ADM-003: Al desactivar un usuario: sesiones activas del usuario se invalidan
RN-ADM-004: La contraseña reseteada por Admin debe ser cambiada en el próximo login
RN-ADM-005: El Administrador no puede ver la contraseña actual de ningún usuario (hash bcrypt)
RN-ADM-006: El email es el identificador único — no puede repetirse
```

---

## 7. Módulo Configuración del Sistema

### 7.1 Funcionalidades

- Configuración de preferencias de interfaz por usuario (tamaño de fuente, modo oscuro)
- Configuración global del sistema (nombre de empresa, logo, moneda)
- Parámetros del sistema (límite de upload, sesión timeout, etc.)

### 7.2 Preferencias de interfaz (por usuario)

```php
// Guardar preferencias
function saveUserPreferences(mysqli $conn, int $user_id, array $prefs): void {
    $stmt = $conn->prepare(
        "INSERT INTO configuracion_interfaz 
            (id_usuario, tamano_fuente, tema_color, modo_oscuro)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            tamano_fuente = VALUES(tamano_fuente),
            tema_color    = VALUES(tema_color),
            modo_oscuro   = VALUES(modo_oscuro)"
    );
    $stmt->bind_param("issi",
        $user_id,
        $prefs['tamano_fuente'],
        $prefs['tema_color'],
        $prefs['modo_oscuro']
    );
    $stmt->execute();
    $stmt->close();
    
    // Actualizar sesión inmediatamente
    $_SESSION['tamano_fuente'] = $prefs['tamano_fuente'];
    $_SESSION['modo_oscuro']   = $prefs['modo_oscuro'];
}
```

### 7.3 Configuración global (tabla pendiente crear)

```sql
CREATE TABLE configuracion_sistema (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  clave         VARCHAR(100) UNIQUE NOT NULL,
  valor         TEXT NOT NULL,
  descripcion   VARCHAR(255),
  fecha_update  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Valores por defecto
INSERT INTO configuracion_sistema (clave, valor, descripcion) VALUES
('nombre_empresa', 'Mi Empresa', 'Nombre que aparece en reportes'),
('moneda', 'USD', 'Moneda del sistema: USD, GTQ, etc.'),
('max_upload_mb', '5', 'Tamaño máximo de archivo en MB'),
('session_timeout', '60', 'Minutos de inactividad antes de expirar sesión'),
('logo_path', 'logo.png', 'Path del logo del sistema');
```

---

## 8. Quality Requirements Transversales

### 8.1 Performance por módulo

| Módulo | Operación | Target |
|--------|-----------|--------|
| Reportes | Generar PDF (100 registros) | < 5s |
| Reportes | Generar Excel (1000 registros) | < 10s |
| Documentos | Upload 5MB | < 15s |
| Documentos | Descarga 5MB | < 5s |
| Gráficas | Cargar dashboard | < 2s |
| Integraciones | Importar CSV 1000 filas | < 30s |
| Admin Usuarios | Listar 100 usuarios | < 200ms |
| Config Sistema | Guardar preferencias | < 100ms |

### 8.2 Seguridad transversal

```
- Reportes: solo Admin puede generarlos
- Documentos: validar MIME antes de guardar, no solo extensión
- Gráficas: datos inyectados con json_encode + JSON_HEX_TAG para prevenir XSS
- Integraciones: whitelist de tablas, validar columnas antes de insertar
- Admin: no puede auto-desactivarse ni ver contraseñas
- Config: sanitizar todos los valores con htmlspecialchars en output
```

### 8.3 Checklist de quality por módulo

**Reportes**:
- [ ] Verificar que el PDF incluye logo, período y fecha de generación
- [ ] Totales calculados correctamente
- [ ] Manejo de reporte vacío (sin datos para el período)
- [ ] El archivo se descarga sin errores en navegadores modernos

**Documentos**:
- [ ] Tipo MIME validado, no solo extensión
- [ ] Nombre del archivo sanitizado (no path traversal)
- [ ] Archivo realmente guardado en uploads/ tras el upload
- [ ] Descarga con headers correctos de Content-Type

**Integraciones**:
- [ ] CSV con encoding UTF-8 procesado correctamente (tildes, ñ)
- [ ] CSV con separador diferente (punto y coma) manejado
- [ ] Filas con datos incompletos manejadas sin detener el proceso
- [ ] Whitelist de tablas aplicada antes de cualquier INSERT

---

## 9. Especificaciones Avanzadas de Generación de Reportes

### 9.1 Estructura de PDF con FPDF — estándar del sistema

```php
// Patrón estándar para todos los PDFs del sistema
class ReporteInventarioPDF extends FPDF {
    private string $titulo;
    private string $periodo;

    public function __construct(string $titulo, string $periodo) {
        parent::__construct('L', 'mm', 'A4'); // Landscape para tablas anchas
        $this->titulo = $titulo;
        $this->periodo = $periodo;
    }

    // Header de página — aparece en cada página
    public function Header(): void {
        // Logo (si existe)
        if (file_exists(__DIR__ . '/logo.png')) {
            $this->Image('logo.png', 10, 8, 25);
        }
        // Título
        $this->SetFont('Arial', 'B', 14);
        $this->Cell(0, 10, utf8_decode($this->titulo), 0, 1, 'C');
        // Período
        $this->SetFont('Arial', 'I', 10);
        $this->Cell(0, 6, utf8_decode("Período: " . $this->periodo), 0, 1, 'C');
        // Línea separadora
        $this->Line(10, $this->GetY(), $this->GetPageWidth() - 10, $this->GetY());
        $this->Ln(4);
    }

    // Footer — número de página
    public function Footer(): void {
        $this->SetY(-15);
        $this->SetFont('Arial', 'I', 8);
        $this->Cell(0, 10,
            utf8_decode("Generado: " . date('d/m/Y H:i') . " | Página " . $this->PageNo() . "/{nb}"),
            0, 0, 'C');
    }
}

// Uso:
$pdf = new ReporteInventarioPDF("Reporte de Inventario", "Enero 2026");
$pdf->AliasNbPages();
$pdf->AddPage();
// ... agregar contenido
$pdf->Output('D', 'reporte_inventario_' . date('Ymd') . '.pdf');
```

### 9.2 Generación de tablas en PDF — patrón adaptativo

```php
// Tabla con anchos de columna adaptados al contenido
function renderTablaEnPDF(FPDF $pdf, array $headers, array $rows, array $widths): void {
    // Header de tabla
    $pdf->SetFont('Arial', 'B', 9);
    $pdf->SetFillColor(52, 73, 94); // Color oscuro para header
    $pdf->SetTextColor(255);
    foreach ($headers as $i => $header) {
        $pdf->Cell($widths[$i], 7, utf8_decode($header), 1, 0, 'C', true);
    }
    $pdf->Ln();

    // Filas con alternancia de color
    $pdf->SetFont('Arial', '', 8);
    $pdf->SetTextColor(0);
    $fill = false;
    foreach ($rows as $row) {
        $pdf->SetFillColor($fill ? 245 : 255, $fill ? 245 : 255, $fill ? 245 : 255);
        foreach ($row as $i => $cell) {
            $align = is_numeric($cell) ? 'R' : 'L';
            $pdf->Cell($widths[$i], 6, utf8_decode((string)$cell), 'LR', 0, $align, $fill);
        }
        $pdf->Ln();
        $fill = !$fill;
        // Nueva página si necesario
        if ($pdf->GetY() > $pdf->GetPageHeight() - 25) {
            $pdf->AddPage();
        }
    }
    // Línea de cierre de tabla
    $pdf->Cell(array_sum($widths), 0, '', 'T');
    $pdf->Ln(4);
}
```

### 9.3 Manejo de reporte vacío (edge case crítico)

```php
// NUNCA dejar un PDF vacío o con error de división por cero
function renderReporteVentas(FPDF $pdf, array $ventas): void {
    if (empty($ventas)) {
        $pdf->SetFont('Arial', 'I', 12);
        $pdf->SetTextColor(150);
        $pdf->Cell(0, 30, utf8_decode("No hay registros para el período seleccionado."), 0, 1, 'C');
        return;
    }

    // Calcular totales con protección contra división por cero
    $total_monto = array_sum(array_column($ventas, 'precio_total'));
    $total_cantidad = array_sum(array_column($ventas, 'cantidad_vendida'));
    $precio_promedio = $total_cantidad > 0 ? $total_monto / $total_cantidad : 0;

    // Renderizar tabla
    renderTablaEnPDF($pdf,
        ['Fecha', 'Producto', 'Cantidad', 'Precio Unit.', 'Total'],
        array_map(fn($v) => [
            $v['fecha_venta'],
            $v['nombre_producto'],
            number_format($v['cantidad_vendida']),
            '$' . number_format($v['precio_unitario'], 2),
            '$' . number_format($v['precio_total'], 2)
        ], $ventas),
        [35, 80, 25, 40, 40]
    );

    // Fila de totales
    $pdf->SetFont('Arial', 'B', 9);
    $pdf->Cell(140, 7, utf8_decode("TOTAL"), 1, 0, 'R');
    $pdf->Cell(40, 7, '$' . number_format($total_monto, 2), 1, 1, 'R');
}
```

---

## 10. Especificaciones de Importación CSV — Validación Avanzada

### 10.1 Pipeline de importación

```
Paso 1: Upload del archivo
  - Validar MIME: text/plain, text/csv, application/vnd.ms-excel
  - Validar tamaño: MAX 5MB
  - Guardar en /uploads/temp/ con nombre único

Paso 2: Detección de formato
  - Detectar separador: coma, punto y coma, pipe, tab
  - Detectar encoding: UTF-8, ISO-8859-1, Windows-1252
  - Convertir a UTF-8 si necesario: mb_convert_encoding()
  - Detectar si tiene header row (primera fila con texto)

Paso 3: Preview (pantalla de mapeo)
  - Mostrar primeras 5 filas del CSV
  - Permitir al usuario mapear columnas CSV → columnas BD
  - Guardar mapeo para futuros imports del mismo proveedor

Paso 4: Validación de datos
  - Validar cada campo según tipo de columna destino
  - Recolectar errores por fila (no abortar al primer error)
  - Mostrar resumen: N filas válidas, M filas con error

Paso 5: Importación
  - Insertar/actualizar solo filas válidas
  - Usar INSERT ... ON DUPLICATE KEY UPDATE para actualizaciones
  - Log de cada registro importado

Paso 6: Reporte de resultados
  - "X registros importados, Y actualizados, Z errores"
  - Opción de descargar reporte de errores en CSV
```

### 10.2 Detección de separador automática

```php
function detectarSeparadorCSV(string $primeraLinea): string {
    $separadores = [',', ';', "\t", '|'];
    $conteos = [];
    foreach ($separadores as $sep) {
        $conteos[$sep] = substr_count($primeraLinea, $sep);
    }
    arsort($conteos);
    $separador = key($conteos);
    return $conteos[$separador] > 0 ? $separador : ',';
}

function detectarEncodingCSV(string $contenido): string {
    $encoding = mb_detect_encoding($contenido, ['UTF-8', 'ISO-8859-1', 'Windows-1252'], true);
    return $encoding ?: 'UTF-8';
}

function normalizarCSV(string $path): string {
    $contenido = file_get_contents($path);
    $encoding = detectarEncodingCSV($contenido);
    if ($encoding !== 'UTF-8') {
        $contenido = mb_convert_encoding($contenido, 'UTF-8', $encoding);
    }
    // Normalizar saltos de línea
    return str_replace(["\r\n", "\r"], "\n", $contenido);
}
```

### 10.3 Importación con ON DUPLICATE KEY UPDATE

```php
// Importar productos desde CSV — actualizando si ya existen (por nombre)
function importarProductosCSV(mysqli $conn, array $filas, array $mapeo, int $id_usuario): array {
    $resultado = ['insertados' => 0, 'actualizados' => 0, 'errores' => []];

    $stmt = $conn->prepare("
        INSERT INTO Inventario (nombre, cantidad_disponible, precio_unitario, stock_minimo)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          cantidad_disponible = VALUES(cantidad_disponible),
          precio_unitario = VALUES(precio_unitario),
          stock_minimo = VALUES(stock_minimo)
    ");

    foreach ($filas as $num_fila => $fila) {
        // Mapear y validar
        $nombre   = validateString($fila[$mapeo['nombre']] ?? '', 1, 255);
        $cantidad = validateInt($fila[$mapeo['cantidad']] ?? 0, 0);
        $precio   = validateDecimal($fila[$mapeo['precio']] ?? 0, 0.01);
        $stock_min = validateInt($fila[$mapeo['stock_min']] ?? 5, 0, 9999);

        if (!$nombre || $cantidad === null || !$precio || $stock_min === null) {
            $resultado['errores'][] = "Fila $num_fila: datos inválidos (" .
                "nombre=" . ($nombre ?? 'NULL') . ", cantidad=$cantidad, precio=$precio)";
            continue;
        }

        $stmt->bind_param("sidd", $nombre, $cantidad, $precio, $stock_min);
        $stmt->execute();

        if ($stmt->affected_rows === 1) $resultado['insertados']++;
        elseif ($stmt->affected_rows === 2) $resultado['actualizados']++;
    }

    $stmt->close();
    return $resultado;
}
```

---

## 11. Patrones de Error Handling por Módulo

### 11.1 Errores esperados y mensajes al usuario

```
MÓDULO REPORTES:
Error: Sin conexión a BD al generar PDF
  → Mensaje: "Error al generar reporte. Por favor intente de nuevo."
  → Log: error_log con detalle de mysqli->error
  → No: mostrar query o stack trace

Error: Sin datos en período seleccionado
  → Comportamiento: generar PDF con mensaje "Sin registros"
  → No: error, página en blanco o excepción

Error: PhpSpreadsheet memory limit al generar Excel grande
  → Mensaje: "El reporte es muy grande. Seleccione un período más corto."
  → Prevención: LIMIT 5000 registros máximo en reportes Excel

MÓDULO DOCUMENTOS:
Error: Archivo demasiado grande (> 5MB)
  → Mensaje: "El archivo supera el límite de 5MB."
  → HTTP response: 400 Bad Request (para uploads AJAX)

Error: Tipo MIME no permitido
  → Mensaje: "Solo se permiten PDF, Excel y TXT."

Error: Directorio uploads/ no tiene permisos de escritura
  → Mensaje: "Error al subir archivo. Contacte al administrador."
  → Log: error_log("UPLOAD_DIR no writable: " . UPLOAD_PATH)
  → Alerta en dashboard de admin

MÓDULO INTEGRACIONES:
Error: CSV con encoding incorrecto tras conversión
  → Mensaje: "Error al procesar el archivo. Asegúrese de guardarlo en UTF-8."

Error: Columna mapeada no existe en CSV (índice fuera de rango)
  → Comportamiento: skip fila, agregar a errores
  → No: fatal error o excepción sin captura

Error: Límite de tiempo PHP al procesar CSV grande
  → Prevención: set_time_limit(120) al inicio del script de importación
  → Alternativa: procesar en chunks de 500 filas
```

### 11.2 Respuestas HTTP estándar para AJAX

```php
// Función helper para respuestas AJAX consistentes
function jsonResponse(bool $success, mixed $data = null, string $error = '', int $httpCode = 200): void {
    http_response_code($httpCode);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => $success,
        'data'    => $data,
        'error'   => $error,
    ], JSON_UNESCAPED_UNICODE | JSON_HEX_TAG);
    exit;
}

// Uso:
jsonResponse(true, ['id' => $id_nuevo, 'mensaje' => 'Documento guardado']);
jsonResponse(false, null, 'Tipo de archivo no permitido', 400);
jsonResponse(false, null, 'No autorizado', 403);
jsonResponse(false, null, 'Recurso no encontrado', 404);
```

---

*Spec actualizada: 2026-04-26T03:37:03Z — PDF avanzado, CSV pipeline, error handling.*
