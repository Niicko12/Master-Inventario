<?php
require('fpdf/fpdf.php');
require_once 'config.php';

$tabla = $_GET['tabla'] ?? '';

if ($tabla) {
    $query = "SELECT * FROM $tabla";
    $result = $conn->query($query);

    if ($result && $result->num_rows > 0) {
        $columns = array_keys($result->fetch_assoc());
        $result->data_seek(0);  // Resetear el puntero para reutilizar los resultados

        $pdf = new FPDF();
        $pdf->AddPage();
        $pdf->SetFont('Arial', 'B', 12);

        // Cabeceras de las columnas
        foreach ($columns as $column) {
            $pdf->Cell(40, 10, ucfirst($column), 1);
        }
        $pdf->Ln();

        // Datos
        while ($row = $result->fetch_assoc()) {
            foreach ($columns as $column) {
                $pdf->Cell(40, 10, $row[$column], 1);
            }
            $pdf->Ln();
        }

        $pdf->Output('D', "reporte_$tabla.pdf");
    } else {
        echo "No se encontraron datos en la tabla seleccionada.";
    }
} else {
    echo "Tabla no seleccionada.";
}
?>
