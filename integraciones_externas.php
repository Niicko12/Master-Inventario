<?php
require_once 'config.php';
$page_title  = 'Integraciones';
$active_page = 'integraciones_externas.php';

requireRole('Administrador');

include('layout/sidebar.php');
?>

<!-- Topbar -->
<div class="topbar">
    <div class="topbar-title">
        <h1>Integraciones Externas</h1>
        <span class="date-badge"><i class="far fa-calendar-alt" style="margin-right:5px;"></i><?= date('d M Y') ?></span>
    </div>
    <div class="topbar-actions">
        <button class="btn-outline" id="sidebarToggle" style="display:none;"><i class="fas fa-bars"></i></button>
    </div>
</div>

<!-- CSV import card -->
<div class="card-master" style="max-width:620px;">
    <div class="card-header-master" style="margin-bottom:20px;">
        <h3><i class="fas fa-file-csv icon-cyan"></i>Importar CSV a Base de Datos</h3>
    </div>

    <form id="csvForm" enctype="multipart/form-data" style="display:flex;flex-direction:column;gap:16px;">
        <div class="form-group">
            <label class="form-label" for="tabla_destino">Tabla de destino</label>
            <select name="tabla_destino" id="tabla_destino" class="form-control" required>
                <option value="" disabled selected>Selecciona una opción</option>
                <option value="Productos">Productos</option>
                <option value="Clientes">Clientes</option>
                <option value="Proveedores">Proveedores</option>
                <option value="Ventas">Ventas</option>
            </select>
        </div>
        <div class="form-group">
            <label class="form-label" for="csv_file">Archivo CSV</label>
            <input type="file" name="csv_file" id="csv_file" class="form-control" accept=".csv" required>
        </div>
        <div>
            <button type="button" id="procesarBtn" class="btn-primary-master">
                <i class="fas fa-cogs" style="margin-right:6px;"></i>Procesar CSV
            </button>
        </div>
    </form>
</div>

<!-- Modal: mapeo de columnas -->
<div class="modal" id="mapeoModal">
    <div class="modal-content" style="max-width:600px;">
        <div class="modal-header">
            <h5>Mapeo de Columnas CSV</h5>
            <button class="modal-close" onclick="closeMapeoModal()">&times;</button>
        </div>
        <div class="modal-body">
            <p style="font-size:13px;color:var(--text-secondary);margin-bottom:4px;">Asigna cada columna del CSV a una columna de la base de datos:</p>
            <form id="mapeoForm" enctype="multipart/form-data" style="display:flex;flex-direction:column;gap:12px;">
                <div id="mapeoContainer"></div>
                <input type="hidden" name="tabla_destino" id="tabla_destino_hidden">
                <input type="file" name="csv_file_modal" id="csv_file_modal" hidden>
            </form>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-secondary-master" onclick="closeMapeoModal()">Cancelar</button>
            <button type="button" id="guardarMapeoBtn" class="btn-primary-master">Procesar</button>
        </div>
    </div>
</div>

<!-- Modal: errores -->
<div class="modal" id="errorModal">
    <div class="modal-content" style="max-width:680px;">
        <div class="modal-header">
            <h5>Errores en los datos</h5>
            <button class="modal-close" onclick="closeErrorModal()">&times;</button>
        </div>
        <div class="modal-body" id="modalBody"></div>
        <div class="modal-footer">
            <button type="button" class="btn-danger-master" id="btnCancelar">Cancelar</button>
            <button type="button" class="btn-secondary-master" id="btnElegirManual">Elegir manualmente</button>
            <button type="button" class="btn-primary-master" id="btnAceptarTodos">Aceptar todos</button>
        </div>
    </div>
</div>

<?php include('integraciones_externas_api.php'); ?>

<script>
function closeMapeoModal() {
    document.getElementById('mapeoModal').style.display = 'none';
}
function closeErrorModal() {
    document.getElementById('errorModal').style.display = 'none';
}
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeMapeoModal();
        closeErrorModal();
    }
});

document.addEventListener('DOMContentLoaded', function() {
    var procesarBtn      = document.getElementById('procesarBtn');
    var guardarMapeoBtn  = document.getElementById('guardarMapeoBtn');
    var mapeoContainer   = document.getElementById('mapeoContainer');
    var tablaDestinoHidden = document.getElementById('tabla_destino_hidden');
    var csvFileModal     = document.getElementById('csv_file_modal');

    procesarBtn.addEventListener('click', async function() {
        var tablaDestino = document.getElementById('tabla_destino').value;
        var csvFile = document.getElementById('csv_file').files[0];

        if (!tablaDestino) { alert('Por favor, selecciona una tabla de destino.'); return; }
        if (!csvFile) { alert('Por favor, selecciona un archivo CSV.'); return; }

        csvFileModal.files = document.getElementById('csv_file').files;

        try {
            var response = await fetch(`procesar_mapeo.php?tabla_destino=${tablaDestino}`);
            if (!response.ok) throw new Error('Error al obtener columnas de la tabla.');
            var columnasBD  = await response.json();
            var columnasCSV = await obtenerColumnasCSV(csvFile);

            mapeoContainer.innerHTML = '';
            columnasCSV.forEach(function(columnaCsv) {
                var div = document.createElement('div');
                div.classList.add('form-group');
                div.innerHTML = `
                    <label class="form-label">Mapear <strong style="color:var(--accent-cyan);">${columnaCsv}</strong></label>
                    <select class="form-control" name="mapeo[${columnaCsv}]" id="map_${columnaCsv}" required>
                        <option value="" disabled selected>Selecciona una columna...</option>
                        ${columnasBD.map(function(c) { return `<option value="${c}">${c}</option>`; }).join('')}
                    </select>`;
                mapeoContainer.appendChild(div);
            });

            tablaDestinoHidden.value = tablaDestino;
            document.getElementById('mapeoModal').style.display = 'flex';
        } catch (error) {
            console.error('Error:', error);
            alert('Error al cargar las columnas. Intenta de nuevo.');
        }
    });

    guardarMapeoBtn.addEventListener('click', async function() {
        var formData     = new FormData(document.getElementById('mapeoForm'));
        var tablaDestino = document.getElementById('tabla_destino').value;
        var mapeoConstruido = {};
        document.querySelectorAll('#mapeoContainer select').forEach(function(select) {
            mapeoConstruido[select.id.replace('map_', '')] = select.value || null;
        });

        try {
            formData.append('mapeo', JSON.stringify(mapeoConstruido));
            formData.append('tabla_destino', tablaDestino);

            var response = await fetch('procesar_datos.php', { method: 'POST', body: formData });
            var result = await response.json();

            if (result.success) {
                alert(result.success);
                var fd = new FormData();
                fd.append('tabla_destino', tablaDestino);
                fd.append('guardar_todos', '1');
                fd.append('datos', JSON.stringify(result.validos));
                var saveResp = await fetch('guardar_todos.php', { method: 'POST', body: fd });
                var saveResult = await saveResp.json();
                if (saveResult.success) { alert('Datos guardados exitosamente.'); }
                else { alert('Error al guardar: ' + saveResult.error); }
            } else if (result.errores) {
                var modalBody = document.getElementById('modalBody');
                modalBody.innerHTML = '<p style="margin-bottom:12px;color:var(--text-secondary);">Se encontraron los siguientes errores:</p>' +
                    result.errores.map(function(e, i) {
                        return `<div style="padding:10px;background:var(--bg-card-alt);border-radius:8px;margin-bottom:8px;font-size:13px;">
                            <strong style="color:var(--accent-pink);">Error ${i+1}:</strong>
                            <pre style="margin:4px 0;color:var(--text-secondary);font-size:12px;">${JSON.stringify(e.fila, null, 2)}</pre>
                        </div>`;
                    }).join('');

                document.getElementById('errorModal').style.display = 'flex';

                document.getElementById('btnAceptarTodos').onclick = async function() {
                    var datosTransformados = result.validos.concat(result.errores.map(function(e) {
                        var filaTransformada = {};
                        for (var k in mapeoConstruido) {
                            if (mapeoConstruido[k] && e.fila[k]) filaTransformada[mapeoConstruido[k]] = e.fila[k];
                        }
                        return filaTransformada;
                    }));
                    var fd = new FormData();
                    fd.append('tabla_destino', tablaDestino);
                    fd.append('guardar_todos', '1');
                    fd.append('datos', JSON.stringify(datosTransformados));
                    var r = await fetch('guardar_todos.php', { method: 'POST', body: fd });
                    var sr = await r.json();
                    if (sr.success) { alert('Todos los datos guardados.'); closeErrorModal(); }
                    else { alert('Error: ' + sr.error); }
                };
                document.getElementById('btnCancelar').onclick = function() { closeErrorModal(); };
                document.getElementById('btnElegirManual').onclick = function() { alert('Función de edición manual disponible.'); };
            } else if (result.error) {
                alert(result.error);
            }
        } catch (error) {
            console.error('Error:', error);
            alert('Error al procesar los datos. Intenta nuevamente.');
        }
    });

    async function obtenerColumnasCSV(file) {
        return new Promise(function(resolve) {
            var reader = new FileReader();
            reader.onload = function(event) {
                var lines = event.target.result.split('\n');
                var headers = lines[0].split(',');
                resolve(headers.map(function(h) { return h.trim(); }));
            };
            reader.readAsText(file);
        });
    }
});
</script>

<?php include('layout/footer_main.php'); ?>
