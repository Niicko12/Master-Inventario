# 🚀 Master Inventario - Senior Excellence Standards

## 💎 UX & UI Professional (Jerarquía y Espacio)
- **Espaciado (White Space):** No amontones los elementos. Usa un sistema de espaciado base de 8px (paddings de 16px, 24px o 32px). La información debe respirar.
- **Jerarquía Visual:** Lo más importante (totales, botones de acción) va arriba y con más peso visual. Lo secundario (listas, logs) va abajo.
- **Micro-interacciones:** Todo elemento interactivo (filas de tabla, botones, inputs) debe tener un `transition: all 0.2s ease-in-out`.
- **Empty States:** Si una tabla está vacía, no dejes un hueco blanco. Diseña un estado "Sin datos" con un icono sutil y un mensaje profesional.

## 📊 Tablas de Datos Avanzadas
- **Limpieza:** Elimina bordes innecesarios. Usa filas con colores alternos muy sutiles o solo bordes inferiores finos.
- **Legibilidad:** Tipografía clara, alineación de números a la derecha y textos a la izquierda. 
- **Acciones:** Los botones de "Editar" o "Eliminar" deben ser iconos elegantes (tipo Lucide), no botones toscos con texto.

## 🛠️ Estándar de Código (Clean Code)
- **DRY (Don't Repeat Yourself):** Si ves que el Sidebar se repite en cada archivo, crea un `layout/sidebar.php` e inclúyelo. 
- **Componentes Reutilizables:** Define una clase CSS `.card-master` que contenga el glassmorphism para usarla en todo el sistema.