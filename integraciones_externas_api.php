<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Integrar API</title>
    <!-- Estilos de Bootstrap -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
</head>
<body>

<div class="container mt-5">
    <h2 class="text-center mb-4">Consumir API</h2>
    <form id="apiForm" class="mb-4">
        <div class="mb-3">
            <label for="api_url" class="form-label">URL de la API:</label>
            <input type="url" name="api_url" id="api_url" class="form-control" placeholder="https://example.com/api" required>
        </div>
        <div class="mb-3">
            <label for="tabla_destino_api" class="form-label">Selecciona la tabla de destino:</label>
            <select name="tabla_destino_api" id="tabla_destino_api" class="form-select" required>
                <option value="" disabled selected>Selecciona una opción</option>
                <option value="Productos">Productos</option>
                <option value="Clientes">Clientes</option>
                <option value="Proveedores">Proveedores</option>
                <option value="Ventas">Ventas</option>
            </select>
        </div>
        <button type="button" id="consumirApiBtn" class="btn btn-primary">Consumir API</button>
    </form>
</div>

<!-- Modal para Mapeo -->
<div id="mapeoApiModal" class="modal fade" tabindex="-1" aria-labelledby="mapeoApiModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="mapeoApiModalLabel">Mapeo de Datos de la API</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p>Los datos de la API contienen las siguientes columnas. Por favor, asigna cada columna de la API a una columna de la base de datos:</p>
                <form id="mapeoApiForm">
                    <div id="mapeoApiContainer"></div>
                    <input type="hidden" name="tabla_destino_api_hidden" id="tabla_destino_api_hidden">
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" id="guardarApiMapeoBtn" class="btn btn-success">Procesar Datos</button>
            </div>
        </div>
    </div>
</div>

<!-- Modal para Errores -->
<div class="modal fade" id="errorApiModal" tabindex="-1" aria-labelledby="errorApiModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="errorApiModalLabel">Errores en los Datos</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="errorApiModalBody"></div>
            <div class="modal-footer">
                <button type="button" id="btnAceptarTodosApi" class="btn btn-success">Aceptar Todos</button>
                <button type="button" id="btnElegirManualApi" class="btn btn-warning">Elegir Manualmente</button>
                <button type="button" id="btnCancelarApi" class="btn btn-danger">Cancelar</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
<script>
document.addEventListener("DOMContentLoaded", () => {
    console.log("DOM cargado. Inicializando eventos...");

    let datosObtenidosDeApi = []; // Variable global para almacenar los datos obtenidos de la API

    const consumirApiBtn = document.getElementById("consumirApiBtn");
    const guardarApiMapeoBtn = document.getElementById("guardarApiMapeoBtn");
    const mapeoApiModalElement = document.getElementById("mapeoApiModal");
    const mapeoApiModal = new bootstrap.Modal(mapeoApiModalElement);
    const mapeoApiContainer = document.getElementById("mapeoApiContainer");
    const tablaDestinoApiHidden = document.getElementById("tabla_destino_api_hidden");

    consumirApiBtn.addEventListener("click", async () => {
        console.log("Botón 'Consumir API' presionado.");

        const apiUrl = document.getElementById("api_url").value;
        const tablaDestino = document.getElementById("tabla_destino_api").value;

        console.log("URL de la API:", apiUrl);
        console.log("Tabla de destino seleccionada:", tablaDestino);

        if (!apiUrl || !tablaDestino) {
            console.warn("Campos incompletos.");
            alert("Por favor, completa todos los campos antes de continuar.");
            return;
        }

        try {
            console.log("Consumir API...");
            const apiResponse = await fetch(apiUrl, { method: "POST" });
            console.log("Respuesta de la API:", apiResponse);

            if (!apiResponse.ok) {
                console.error("Error al consumir la API:", apiResponse.statusText);
                throw new Error(`Error al consumir la API: ${apiResponse.statusText}`);
            }

            datosObtenidosDeApi = await apiResponse.json(); // Guardar los datos en la variable global
            console.log("Datos obtenidos de la API:", datosObtenidosDeApi);

            if (!Array.isArray(datosObtenidosDeApi) || datosObtenidosDeApi.length === 0) {
                console.warn("La API no devolvió datos válidos.");
                throw new Error("La API no devolvió datos válidos.");
            }

            const columnasApi = Object.keys(datosObtenidosDeApi[0]);
            console.log("Columnas detectadas en la API:", columnasApi);

            console.log("Solicitando columnas de la base de datos...");
            const columnasBDResponse = await fetch(`procesar_mapeo_api.php?tabla_destino=${tablaDestino}`);
            console.log("Respuesta de procesar_mapeo_api.php:", columnasBDResponse);

            if (!columnasBDResponse.ok) {
                console.error("Error al obtener columnas de la base de datos:", columnasBDResponse.statusText);
                throw new Error("Error al obtener columnas de la base de datos.");
            }

            const columnasBD = await columnasBDResponse.json();
            console.log("Columnas de la base de datos:", columnasBD);

            if (!Array.isArray(columnasBD) || columnasBD.length === 0) {
                console.warn("No se encontraron columnas para la tabla seleccionada.");
                throw new Error("No se encontraron columnas para la tabla seleccionada.");
            }

            console.log("Preparando mapeo...");
            mapeoApiContainer.innerHTML = columnasApi.map((columna) => `
                <div class="mb-3">
                    <label for="map_${columna}" class="form-label">Mapear <strong>${columna}</strong>:</label>
                    <select class="form-select" name="mapeoApi[${columna}]" id="map_${columna}" required>
                        <option value="" disabled selected>Selecciona una columna...</option>
                        ${columnasBD.map((columnaBD) => `<option value="${columnaBD}">${columnaBD}</option>`).join("")}
                    </select>
                </div>
            `).join("");

            tablaDestinoApiHidden.value = tablaDestino;
            mapeoApiModal.show();
            console.log("Modal de mapeo mostrado.");
        } catch (error) {
            console.error("Error en el consumo de la API o preparación del mapeo:", error);
            alert(`Ocurrió un error: ${error.message}`);
        }
    });

    guardarApiMapeoBtn.addEventListener("click", async () => {
        console.log("Botón 'Procesar Datos' del modal presionado.");

        const formData = new FormData(document.getElementById("mapeoApiForm"));
        formData.append("tabla_destino", document.getElementById("tabla_destino_api_hidden").value);
        formData.append("datosApi", JSON.stringify(datosObtenidosDeApi)); // Enviar los datos obtenidos de la API

        console.log("Datos enviados (antes de enviar):", Object.fromEntries(formData.entries())); // Ver los datos enviados

        try {
            console.log("Enviando datos a procesar_datos_api.php...");

            const response = await fetch("procesar_datos_api.php", {
                method: "POST",
                body: formData,
            });

            console.log("Respuesta del servidor para procesar_datos_api.php:", response);

            if (!response.ok) {
                console.error("Error en el servidor al procesar datos. Estado HTTP:", response.status, response.statusText);
                throw new Error(`Error en el servidor: ${response.statusText}`);
            }

            const result = await response.json();
            console.log("Respuesta JSON recibida:", result);

            if (result.success) {
                alert(result.mensaje);
                console.log("Datos procesados correctamente:", result.mensaje);
            } else if (result.error) {
                alert(result.error);
                console.error("Error recibido del servidor:", result.error);
            }
        } catch (error) {
            console.error("Error al procesar los datos:", error);
            alert(`Hubo un error al procesar los datos: ${error.message}`);
        }
    });
});


</script>
</body>
</html>
