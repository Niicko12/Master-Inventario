<?php
require('fpdf/fpdf.php');
require_once 'config.php';

class PDF extends FPDF {
    // Cabecera de la página
    function Header() {
        // Ruta del logo y ajuste de tamaño
        $logo_path = 'logo.png'; // Cambia esta ruta por la ubicación real de tu logo
        if (file_exists($logo_path)) {
            $this->Image($logo_path, 170, 10, 30); // Coloca el logo en (170, 10) con ancho de 30
        }
        // Mover hacia la derecha
        $this->SetXY(50, 10); // Ajusta el margen para empezar después del logo
        $this->SetFont('Arial', 'B', 12);
        $this->Cell(0, 10, 'Factura de Ventas', 0, 1, 'C');
        $this->Ln(20); // Espacio adicional después del título
    }

    // Pie de página
    function Footer() {
        $this->SetY(-15);
        $this->SetFont('Arial', 'I', 8);
        $this->Cell(0, 10, 'Pagina ' . $this->PageNo(), 0, 0, 'C');
    }
}

// Crear el PDF
$pdf = new PDF();
$pdf->AddPage();
$pdf->SetFont('Arial', '', 10);

// Consultar la base de datos para obtener la información de la factura
$query = "SELECT V.id_venta, U.nombre AS cliente, U.direccion, U.telefono, V.fecha_venta, V.monto_total 
          FROM Ventas V 
          JOIN Usuarios U ON V.id_cliente = U.id_usuario";
$result = $conn->query($query);

$totalVentas = 0; // Inicializar la variable para el total de ventas

if ($result && $result->num_rows > 0) {
    // Información del cliente
    $row = $result->fetch_assoc();
    $pdf->SetX(10); // Mover a la posición inicial
    $pdf->Cell(0, 10, 'Cliente: ' . $row['cliente'], 0, 1);
    $pdf->Cell(0, 10, 'Direccion: ' . $row['direccion'], 0, 1);
    $pdf->Cell(0, 10, 'Telefono: ' . $row['telefono'], 0, 1);
    $pdf->Cell(0, 10, 'Fecha de Venta: ' . $row['fecha_venta'], 0, 1);
    $pdf->Ln(10);

    // Cabecera de la tabla
    $pdf->SetFont('Arial', 'B', 10);
    $pdf->Cell(40, 10, 'ID Venta', 1);
    $pdf->Cell(60, 10, 'Cliente', 1);
    $pdf->Cell(40, 10, 'Fecha de Venta', 1);
    $pdf->Cell(40, 10, 'Monto Total', 1);
    $pdf->Ln();

    // Datos de la tabla
    do {
        $pdf->SetFont('Arial', '', 10);
        $pdf->Cell(40, 10, $row['id_venta'], 1);
        $pdf->Cell(60, 10, $row['cliente'], 1);
        $pdf->Cell(40, 10, $row['fecha_venta'], 1);
        $pdf->Cell(40, 10, number_format($row['monto_total'], 2), 1);
        $pdf->Ln();

        $totalVentas += $row['monto_total']; // Sumar el monto de cada venta al total
    } while ($row = $result->fetch_assoc());

    // Total de ventas
    $pdf->SetFont('Arial', 'B', 10);
    $pdf->Cell(140, 10, 'Total de Ventas', 1);
    $pdf->Cell(40, 10, number_format($totalVentas, 2), 1);
} else {
    $pdf->Cell(0, 10, 'No se encontraron datos para generar la factura.', 1, 1, 'C');
}

// Salida del archivo PDF
$pdf->Output('I', 'factura_ventas.pdf');
?>
