# Especificación Técnica — Módulo Auth

---
name: spec-auth
module: auth
status: active
created: 2026-04-24T21:19:11Z
updated: 2026-04-24T21:19:11Z
---

## Índice

1. [Visión General](#1-visión-general)
2. [Archivos del Módulo](#2-archivos-del-módulo)
3. [Máquinas de Estado](#3-máquinas-de-estado)
4. [Casos de Uso Detallados](#4-casos-de-uso-detallados)
5. [Flujos de Autenticación](#5-flujos-de-autenticación)
6. [Validaciones y Reglas de Negocio](#6-validaciones-y-reglas-de-negocio)
7. [Manejo de Sesiones](#7-manejo-de-sesiones)
8. [Integración Firebase](#8-integración-firebase)
9. [Integración PHPMailer](#9-integración-phpmailer)
10. [Seguridad](#10-seguridad)
11. [Edge Cases](#11-edge-cases)
12. [APIs del Módulo](#12-apis-del-módulo)
13. [Schema de BD Relacionado](#13-schema-de-bd-relacionado)
14. [Organización Interna de Código](#14-organización-interna-de-código)
15. [Quality Requirements](#15-quality-requirements)
16. [Testing Scenarios](#16-testing-scenarios)

---

## 1. Visión General

### Propósito
El módulo Auth gestiona todo el ciclo de vida de la identidad de un usuario en el sistema: registro, verificación de correo, inicio de sesión (con reCAPTCHA y opcionalmente 2FA), mantenimiento de sesión, recuperación de contraseña y cierre de sesión.

### Principios de diseño
- Seguridad primero: ningún usuario autenticado debe acceder a funcionalidades fuera de su rol
- 2FA obligatoria para administradores (phone via Firebase o email OTP)
- Credenciales nunca expuestas en logs, console ni respuestas HTTP
- Todas las contraseñas almacenadas con bcrypt (cost ≥ 12)

### Roles del sistema
| Rol | Descripción | 2FA | Acceso |
|-----|-------------|-----|--------|
| Administrador | Gestión completa del negocio | ✅ Obligatoria | Total |
| Empleado | Operaciones del día a día | ✗ | Parcial |
| Usuario | Clientes / consultores | ✗ | Solo lectura |

---

## 2. Archivos del Módulo

| Archivo | Responsabilidad | Acceso |
|---------|----------------|--------|
| `login.php` | Formulario + procesamiento de login | Público |
| `register.php` | Formulario + procesamiento de registro | Público |
| `logout.php` | Destrucción de sesión | Autenticado |
| `recuperar_contraseña.php` | Solicitar reset de contraseña | Público |
| `cambiar_contraseña.php` | Cambiar contraseña con token | Público |
| `verificacion_2fa.php` | Pantalla de 2FA (Firebase phone o email OTP) | Temp session |
| `verificacion_correo.php` | Verificar email tras registro | Público (con token) |
| `verificar_codigo.php` | Verificar código OTP email (2FA alternativo) | Temp session |
| `guardar_sesion_temp.php` | Endpoint AJAX — guardar datos temporales | Público |
| `guardar_codigo.php` | Endpoint AJAX — guardar código OTP | Temp session |
| `enviar_correo_confirmacion.php` | Endpoint AJAX — enviar OTP por email | Temp session |

### Archivos compartidos que depende el módulo
- `config.php` — conexión BD
- `header.php` — layout + inicio de sesión
- `vendor/autoload.php` — PHPMailer
- `js/firebase-config.js` — SDK Firebase

---

## 3. Máquinas de Estado

### 3.1 Estado de Usuario

```
[Pendiente de Verificación]
    │ correo_verificado = false (estado en BD)
    │ Usuario hace clic en link de verificación
    ▼
[Activo]
    │ estado = 'Activo'
    │ Admin lo desactiva
    ▼
[Inactivo]
    │ estado = 'Inactivo'
    │ Admin lo reactiva
    ▼
[Activo]
```

**Transiciones válidas**:
- `Pendiente` → `Activo`: solo via link de verificación de email
- `Activo` → `Inactivo`: solo Admin puede hacer esta transición
- `Inactivo` → `Activo`: solo Admin puede hacer esta transición
- No existe estado "Eliminado": los usuarios no se borran, solo se desactivan

### 3.2 Estado de Sesión — Usuario Normal (Empleado/Usuario)

```
[Sin sesión]
    │ Accede a login.php
    │ Completa reCAPTCHA
    │ Envía credenciales válidas
    ▼
[Sesión Activa]
    │ Variables: user_id, user_role, nombre, email, telefono, tamano_fuente
    │ Accede a logout.php o sesión expira
    ▼
[Sin sesión]
```

### 3.3 Estado de Sesión — Administrador (con 2FA)

```
[Sin sesión]
    │ Accede a login.php
    │ Completa reCAPTCHA
    │ Envía credenciales válidas (rol = Administrador)
    ▼
[Sesión Temporal]
    │ Variables: temp_user_id, temp_user_role, temp_telefono, temp_email, temp_nombre
    │ Redirige a verificacion_2fa.php
    │
    ├──[Opción A: Firebase Phone 2FA]
    │   │ Firebase envía SMS al temp_telefono
    │   │ Usuario ingresa código SMS
    │   │ Firebase verifica
    │   ▼
    │ [Sesión Activa]
    │
    └──[Opción B: Email OTP]
        │ Sistema genera código de 6 dígitos
        │ PHPMailer envía código al temp_email
        │ Usuario ingresa código
        │ PHP verifica vs $_SESSION['verification_code']
        ▼
    [Sesión Activa]
        │ Variables: user_id, user_role, nombre, email, telefono, tamano_fuente
        │ Variables temp_* eliminadas
        │ Redirige a index.php
```

### 3.4 Estado de Recuperación de Contraseña

```
[Usuario sin acceso]
    │ Accede a recuperar_contraseña.php
    │ Ingresa email registrado
    ▼
[Token enviado]
    │ Sistema genera token único + expiry (1 hora)
    │ PHPMailer envía link con token al email
    │ Usuario hace clic en link
    ▼
[Token válido]
    │ Sistema verifica token no expirado
    │ Usuario ingresa nueva contraseña (+ confirmación)
    │ Contraseña guardada con password_hash() bcrypt
    │ Token invalidado
    ▼
[Contraseña actualizada]
    │ Redirige a login.php con mensaje de éxito
```

### 3.5 Estado de Verificación de Correo (Registro)

```
[Cuenta creada — no verificada]
    │ Sistema genera token de verificación
    │ PHPMailer envía email con link
    │ Usuario hace clic en link
    ▼
[Token válido]
    │ Sistema marca cuenta como verificada
    │ estado = 'Activo'
    ▼
[Cuenta activa — puede hacer login]
```

---

## 4. Casos de Uso Detallados

### CU-001: Login estándar (Empleado/Usuario)

**Actor**: Empleado o Usuario  
**Precondición**: Usuario existe, estado = 'Activo', contraseña correcta  
**Postcondición**: Sesión activa, redirige a index.php

**Flujo principal**:
1. Usuario accede a `login.php`
2. Firebase reCAPTCHA se inicializa automáticamente
3. Usuario ingresa email y contraseña
4. Usuario hace clic en "Iniciar Sesión"
5. Firebase verifica reCAPTCHA (onSubmit)
6. Si reCAPTCHA válido → submit del formulario
7. PHP valida: detectar patrones SQL injection en email/password
8. PHP ejecuta SELECT por email, verifica estado = 'Activo'
9. PHP verifica password_verify()
10. PHP crea sesión: `user_id`, `user_role`, `nombre`, `email`, `telefono`
11. PHP carga preferencias de UI desde `configuracion_interfaz`
12. PHP redirige a `index.php`

**Flujo alternativo — SQL injection detectado**:
- En paso 7: si email o password contienen patrones sospechosos
- Sistema registra en tabla `IntentosInyeccionSQL`
- Muestra mensaje de error genérico (no revela que fue detectado)
- NO redirige ni continúa el flujo

**Flujo alternativo — Credenciales incorrectas**:
- En paso 9: password_verify falla
- Muestra: "La contraseña es incorrecta"
- NO registra intento en tabla de intentos fallidos (pendiente implementar)

**Flujo alternativo — Usuario no encontrado**:
- En paso 8: no existe usuario con ese email o estado ≠ 'Activo'
- Muestra: "No se encontró una cuenta con ese correo electrónico"
- Mensaje no diferencia entre "no existe" y "inactivo" (por seguridad)

---

### CU-002: Login con 2FA (Administrador)

**Actor**: Administrador  
**Precondición**: Usuario existe, rol = 'Administrador', estado = 'Activo'  
**Postcondición**: Sesión completa activa, redirige a index.php

**Flujo principal (Firebase Phone)**:
1. Pasos 1-9 del CU-001
2. En paso 10: rol = 'Administrador' → NO crear sesión completa aún
3. Crear sesión temporal: `temp_user_id`, `temp_user_role`, `temp_telefono`, `temp_email`, `temp_nombre`
4. Redirige a `verificacion_2fa.php`
5. Firebase inicializa RecaptchaVerifier (para phone auth)
6. Usuario hace clic en "Verificar por SMS"
7. `firebase.auth.signInWithPhoneNumber(telefono, recaptchaVerifier)`
8. Firebase envía SMS al `temp_telefono`
9. Usuario ingresa código SMS
10. `confirmationResult.confirm(code)`
11. Firebase retorna éxito
12. JavaScript llama a endpoint PHP para promover sesión temporal a completa
13. PHP crea sesión completa, limpia variables temp_*
14. PHP redirige a `index.php`

**Flujo alternativo (Email OTP)**:
1. Pasos 1-4 del flujo principal
5. Usuario hace clic en "Verificar por Email"
6. JavaScript llama a `enviar_correo_confirmacion.php`
7. PHP genera OTP de 6 dígitos, guarda en `$_SESSION['verification_code']`
8. PHPMailer envía OTP al `temp_email`
9. Redirige a `verificar_codigo.php`
10. Usuario ingresa OTP
11. PHP verifica OTP vs `$_SESSION['verification_code']`
12. PHP crea sesión completa, limpia variables temp_*
13. PHP redirige a `index.php`

---

### CU-003: Registro de nuevo usuario

**Actor**: Público (cualquier persona)  
**Precondición**: Email no registrado previamente  
**Postcondición**: Cuenta creada con estado pendiente, email de verificación enviado

**Flujo principal**:
1. Usuario accede a `register.php`
2. Usuario completa el formulario: nombre, email, contraseña, confirmar contraseña, teléfono, rol solicitado
3. PHP valida todos los campos (ver sección 6.1)
4. PHP verifica que el email no exista ya en BD
5. PHP genera hash bcrypt de la contraseña
6. PHP inserta el usuario en BD con `estado = 'Pendiente'` (o directamente 'Activo' según config)
7. PHP genera token único de verificación
8. PHP guarda token en BD (tabla de tokens o campo en Usuarios)
9. PHPMailer envía email de bienvenida con link de verificación
10. Muestra mensaje: "Revisa tu correo para activar tu cuenta"

**Flujo alternativo — Email ya registrado**:
- En paso 4: ya existe email
- Muestra: "Este correo ya está registrado"
- Opcionalmente: "¿Olvidaste tu contraseña?"

**Flujo alternativo — Contraseñas no coinciden**:
- En paso 3: contraseña ≠ confirmar contraseña
- Muestra error en el campo correspondiente

---

### CU-004: Recuperación de contraseña

**Actor**: Usuario (cualquier rol)  
**Precondición**: Email registrado en el sistema  
**Postcondición**: Contraseña actualizada, usuario puede hacer login

**Flujo principal**:
1. Usuario accede a `recuperar_contraseña.php`
2. Usuario ingresa email
3. PHP busca usuario por email (estado = 'Activo')
4. PHP genera token de recuperación (uniqid() o random_bytes(32) → bin2hex)
5. PHP almacena token con timestamp de expiración (+1 hora)
6. PHPMailer envía email con link: `cambiar_contraseña.php?token=TOKEN`
7. Muestra: "Se envió un enlace de recuperación a tu correo"
8. Usuario hace clic en link del email
9. `cambiar_contraseña.php` verifica token existe y no expiró
10. Muestra formulario de nueva contraseña
11. Usuario ingresa nueva contraseña + confirmación
12. PHP valida contraseña (ver reglas sección 6.2)
13. PHP actualiza contraseña con password_hash() bcrypt
14. PHP invalida el token (eliminarlo o marcar como usado)
15. Redirige a `login.php` con mensaje de éxito

**Flujo alternativo — Email no registrado**:
- En paso 3: no existe usuario o está Inactivo
- Muestra el MISMO mensaje del paso 7 (no revelar si el email existe)
- No envía email

**Flujo alternativo — Token expirado**:
- En paso 9: token tiene más de 1 hora
- Muestra: "El enlace ha expirado. Solicita uno nuevo."
- Link a recuperar_contraseña.php

---

### CU-005: Logout

**Actor**: Cualquier usuario autenticado  
**Precondición**: Sesión activa  
**Postcondición**: Sesión destruida, cookie eliminada, redirige a login.php

**Flujo**:
1. Usuario hace clic en "Cerrar Sesión"
2. GET a `logout.php`
3. PHP: `session_start()` → `session_unset()` → `session_destroy()`
4. PHP elimina cookie de sesión
5. PHP redirige a `login.php`

---

## 5. Flujos de Autenticación

### 5.1 Verificación de sesión en páginas protegidas

```php
// auth_check.php — helper a usar en TODAS las páginas
function requireAuth() {
    if (!isset($_SESSION['user_id'])) {
        header("Location: login.php");
        exit;
    }
}

function requireRole(string $role) {
    requireAuth();
    if ($_SESSION['user_role'] !== $role) {
        header("Location: index.php");
        exit;
    }
}

function requireRoles(array $roles) {
    requireAuth();
    if (!in_array($_SESSION['user_role'], $roles)) {
        header("Location: index.php");
        exit;
    }
}
```

### 5.2 Patrón de uso en páginas

```php
<?php
include('header.php'); // inicia sesión, carga $user_role
// Para página solo autenticados:
if (!$user_logged_in) { header("Location: login.php"); exit; }

// Para página solo Administrador:
if ($user_role !== 'Administrador') { header("Location: index.php"); exit; }

// Para página Administrador + Empleado:
if (!in_array($user_role, ['Administrador', 'Empleado'])) { 
    header("Location: index.php"); exit; 
}
```

### 5.3 Flujo de promoción de sesión temporal a completa

```php
// Después de verificar 2FA exitosamente
function promoteSession() {
    // Tomar datos de sesión temporal
    $user_id   = $_SESSION['temp_user_id'];
    $user_role = $_SESSION['temp_user_role'];
    $telefono  = $_SESSION['temp_telefono'];
    $email     = $_SESSION['temp_email'];
    $nombre    = $_SESSION['temp_nombre'];
    
    // Limpiar sesión temporal
    unset($_SESSION['temp_user_id'], $_SESSION['temp_user_role'],
          $_SESSION['temp_telefono'], $_SESSION['temp_email'],
          $_SESSION['temp_nombre'], $_SESSION['verification_code']);
    
    // Crear sesión completa
    $_SESSION['user_id']   = $user_id;
    $_SESSION['user_role'] = $user_role;
    $_SESSION['telefono']  = $telefono;
    $_SESSION['email']     = $email;
    $_SESSION['nombre']    = $nombre;
    
    // Cargar preferencias UI
    loadUserPreferences($user_id);
}

function loadUserPreferences(int $userId) {
    global $conn;
    $stmt = $conn->prepare(
        "SELECT tamano_fuente, tema_color, modo_oscuro 
         FROM configuracion_interfaz WHERE id_usuario = ?"
    );
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $prefs = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    
    $_SESSION['tamano_fuente'] = $prefs['tamano_fuente'] ?? 'mediano';
    $_SESSION['tema_color']    = $prefs['tema_color'] ?? null;
    $_SESSION['modo_oscuro']   = $prefs['modo_oscuro'] ?? 0;
}
```

---

## 6. Validaciones y Reglas de Negocio

### 6.1 Validaciones de registro

| Campo | Validación | Mensaje de error |
|-------|-----------|-----------------|
| nombre | Requerido, 2-100 chars, solo letras y espacios | "El nombre solo puede contener letras y espacios" |
| correo_electronico | Requerido, formato email válido, único en BD | "Correo inválido" / "Este correo ya está registrado" |
| contrasena | Ver sección 6.2 | Ver 6.2 |
| contrasena_confirm | Debe coincidir con contrasena | "Las contraseñas no coinciden" |
| telefono | Formato internacional: +[código país][número] | "Formato: +50312345678" |
| rol | ENUM válido | — (solo dropdown) |

```php
// Validación de email
function validateEmail(string $email): bool {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

// Validación de teléfono (formato Firebase)
function validatePhone(string $phone): bool {
    return preg_match('/^\+[1-9]\d{7,14}$/', $phone) === 1;
}

// Verificar email único
function isEmailTaken(mysqli $conn, string $email): bool {
    $stmt = $conn->prepare("SELECT id_usuario FROM Usuarios WHERE correo_electronico = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $stmt->store_result();
    $exists = $stmt->num_rows > 0;
    $stmt->close();
    return $exists;
}
```

### 6.2 Reglas de contraseña

**Requisitos mínimos**:
- Mínimo 8 caracteres
- Al menos 1 letra mayúscula (A-Z)
- Al menos 1 letra minúscula (a-z)
- Al menos 1 número (0-9)
- Al menos 1 carácter especial: `!@#$%^&*()_+-=[]{}|;':,.<>?`

```php
function validatePassword(string $password): array {
    $errors = [];
    
    if (strlen($password) < 8) {
        $errors[] = "Mínimo 8 caracteres";
    }
    if (!preg_match('/[A-Z]/', $password)) {
        $errors[] = "Al menos una letra mayúscula";
    }
    if (!preg_match('/[a-z]/', $password)) {
        $errors[] = "Al menos una letra minúscula";
    }
    if (!preg_match('/[0-9]/', $password)) {
        $errors[] = "Al menos un número";
    }
    if (!preg_match('/[!@#$%^&*()\-_=+\[\]{}|;:,.<>?]/', $password)) {
        $errors[] = "Al menos un carácter especial";
    }
    
    return $errors;
}
```

### 6.3 Detección de SQL injection en login

```php
// Patrón de detección (solo para logging, el prepared statement ya previene la inyección)
$sqli_pattern = "/(union|select|insert|delete|update|drop|;|--|'|\")/i";

function detectSQLInjection(mysqli $conn, string $input, string $ip): bool {
    $pattern = "/(union|select|insert|delete|update|drop|;|--|'|\")/i";
    if (preg_match($pattern, $input)) {
        $stmt = $conn->prepare(
            "INSERT INTO IntentosInyeccionSQL (intento, ip) VALUES (?, ?)"
        );
        $stmt->bind_param("ss", $input, $ip);
        $stmt->execute();
        $stmt->close();
        return true;
    }
    return false;
}
```

### 6.4 Generación de OTP email

```php
function generateOTP(int $digits = 6): string {
    return str_pad((string) random_int(0, (10 ** $digits) - 1), $digits, '0', STR_PAD_LEFT);
}
```

### 6.5 Generación de tokens de recuperación

```php
function generateResetToken(): string {
    return bin2hex(random_bytes(32)); // 64 chars hex
}

function saveResetToken(mysqli $conn, int $userId, string $token): void {
    $expiry = date('Y-m-d H:i:s', strtotime('+1 hour'));
    $stmt = $conn->prepare(
        "UPDATE Usuarios SET reset_token = ?, reset_token_expiry = ? WHERE id_usuario = ?"
    );
    $stmt->bind_param("ssi", $token, $expiry, $userId);
    $stmt->execute();
    $stmt->close();
}

function verifyResetToken(mysqli $conn, string $token): ?array {
    $stmt = $conn->prepare(
        "SELECT id_usuario, reset_token_expiry FROM Usuarios 
         WHERE reset_token = ? AND estado = 'Activo'"
    );
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    
    if (!$row) return null;
    if (strtotime($row['reset_token_expiry']) < time()) return null; // expirado
    
    return $row;
}
```

---

## 7. Manejo de Sesiones

### 7.1 Variables de sesión — definición completa

```php
// SESIÓN TEMPORAL (solo durante 2FA de administradores)
$_SESSION['temp_user_id']       // int  — ID del usuario pendiente
$_SESSION['temp_user_role']     // str  — 'Administrador'
$_SESSION['temp_telefono']      // str  — '+50312345678'
$_SESSION['temp_email']         // str  — 'admin@empresa.com'
$_SESSION['temp_nombre']        // str  — 'Nombre Completo'
$_SESSION['verification_code']  // str  — '123456' (OTP email)

// SESIÓN COMPLETA (todos los usuarios autenticados)
$_SESSION['user_id']            // int  — ID del usuario
$_SESSION['user_role']          // str  — 'Administrador'|'Empleado'|'Usuario'
$_SESSION['nombre']             // str  — nombre completo
$_SESSION['email']              // str  — correo electrónico
$_SESSION['telefono']           // str  — teléfono con código de país
$_SESSION['tamano_fuente']      // str  — 'pequeño'|'mediano'|'grande'
$_SESSION['tema_color']         // str|null — tema de color (futuro)
$_SESSION['modo_oscuro']        // int  — 0|1
```

### 7.2 Ciclo de vida de la sesión

```
Inicio:   session_start() — siempre verificar PHP_SESSION_NONE
Lectura:  $_SESSION['key'] ?? $default
Escritura: $_SESSION['key'] = $value
Borrado:  unset($_SESSION['key'])
Fin:      session_unset() + session_destroy()
```

### 7.3 Configuración de sesión recomendada (php.ini o en código)

```php
// Antes de session_start() en config.php o header.php
ini_set('session.cookie_httponly', 1);  // Prevenir acceso JS a cookie
ini_set('session.cookie_secure', 1);    // Solo HTTPS (producción)
ini_set('session.use_strict_mode', 1);  // Prevenir session fixation
ini_set('session.gc_maxlifetime', 3600); // 1 hora de inactividad
```

---

## 8. Integración Firebase

### 8.1 Configuración del proyecto

```javascript
// js/firebase-config.js
const firebaseConfig = {
    apiKey: "AIzaSyA-UyiOVrrdJ83IR67BvR28kkiUEX8LtDA",
    authDomain: "comercioelectronico-811d2.firebaseapp.com",
    projectId: "comercioelectronico-811d2",
    storageBucket: "comercioelectronico-811d2.appspot.com",
    messagingSenderId: "293142780579",
    appId: "1:293142780579:web:6fad3b87cb5c6e9077bd16"
};
firebase.initializeApp(firebaseConfig);
```

### 8.2 reCAPTCHA en login.php

```javascript
// Inicialización del reCAPTCHA (modo visible)
window.recaptchaVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-container', {
    size: 'normal',
    callback: function(response) {
        // reCAPTCHA resuelto — habilitar botón de login
    },
    'expired-callback': function() {
        // reCAPTCHA expirado — mostrar mensaje
    }
});
window.recaptchaVerifier.render();

// Antes de submit: verificar reCAPTCHA
function onSubmit() {
    window.recaptchaVerifier.verify()
        .then(function(response) {
            document.getElementById('login-form').submit();
        })
        .catch(function(error) {
            alert("Por favor completa el reCAPTCHA");
        });
}
```

### 8.3 Phone 2FA en verificacion_2fa.php

```javascript
// Enviar SMS con código
function sendPhoneVerification(phoneNumber) {
    const appVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-2fa', {
        size: 'invisible'
    });
    
    firebase.auth().signInWithPhoneNumber(phoneNumber, appVerifier)
        .then(function(confirmationResult) {
            window.confirmationResult = confirmationResult;
            // Mostrar campo para ingresar código SMS
        })
        .catch(function(error) {
            console.error("Error enviando SMS:", error);
            // Ofrecer opción de email OTP
        });
}

// Verificar código SMS
function verifyPhoneCode(code) {
    window.confirmationResult.confirm(code)
        .then(function(result) {
            // Firebase auth exitoso
            // Llamar a PHP para promover sesión
            fetch('update_session.php', {
                method: 'POST',
                body: JSON.stringify({ action: 'promote_session' }),
                headers: { 'Content-Type': 'application/json' }
            }).then(r => r.json())
              .then(data => {
                  if (data.success) window.location.href = 'index.php';
              });
        })
        .catch(function(error) {
            console.error("Código incorrecto:", error);
            alert("Código inválido. Intenta de nuevo.");
        });
}
```

### 8.4 Limitaciones de Firebase Phone Auth

- Requiere número de teléfono con código de país válido
- Límite de SMS gratuitos en plan Spark de Firebase
- Latencia de entrega de SMS puede variar (por eso existe el fallback de email)
- No funciona en localhost sin configuración especial de dominio autorizado

---

## 9. Integración PHPMailer

### 9.1 Configuración base

```php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require_once 'vendor/autoload.php';

function createMailer(): PHPMailer {
    $mail = new PHPMailer(true);
    $mail->isSMTP();
    $mail->Host       = 'smtp.gmail.com'; // o smtp.hostinger.com
    $mail->SMTPAuth   = true;
    $mail->Username   = getenv('MAIL_USERNAME');
    $mail->Password   = getenv('MAIL_PASSWORD');
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port       = 587;
    $mail->CharSet    = 'UTF-8';
    $mail->setFrom(getenv('MAIL_FROM'), 'Sistema de Gestión');
    return $mail;
}
```

### 9.2 Plantillas de email

**Email de verificación de cuenta**:
```
Asunto: Activa tu cuenta en Sistema de Gestión
Cuerpo:
  Hola {nombre},
  
  Haz clic en el siguiente enlace para activar tu cuenta:
  {base_url}/verificacion_correo.php?token={token}
  
  Este enlace expira en 24 horas.
  
  Si no creaste esta cuenta, ignora este mensaje.
```

**Email de recuperación de contraseña**:
```
Asunto: Recuperación de contraseña
Cuerpo:
  Hola {nombre},
  
  Recibimos una solicitud para restablecer tu contraseña.
  Haz clic en el siguiente enlace:
  {base_url}/cambiar_contraseña.php?token={token}
  
  Este enlace expira en 1 hora.
  
  Si no solicitaste esto, ignora este mensaje.
```

**Email de código OTP (2FA alternativo)**:
```
Asunto: Código de verificación — {codigo}
Cuerpo:
  Tu código de verificación es: {codigo}
  
  Ingresa este código en la pantalla de verificación.
  El código expira en 10 minutos.
  
  No compartas este código con nadie.
```

---

## 10. Seguridad

### 10.1 Protecciones implementadas

| Ataque | Protección | Implementación |
|--------|-----------|----------------|
| SQL Injection | Prepared statements + detección | mysqli::prepare |
| XSS | htmlspecialchars en outputs | Pendiente completar |
| CSRF | reCAPTCHA en login | Firebase reCAPTCHA |
| Brute force | reCAPTCHA (parcial) | Pendiente: rate limiting |
| Session fixation | session.use_strict_mode | Pendiente configurar |
| Password theft | bcrypt (cost 12) | password_hash() |
| Clickjacking | X-Frame-Options | Pendiente header global |
| Enumeration | Mensajes genéricos | Parcialmente implementado |

### 10.2 Headers de seguridad recomendados

```php
// En header.php o config.php
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: SAMEORIGIN');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://www.gstatic.com https://www.google.com; style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com https://cdn.jsdelivr.net; font-src 'self' https://cdnjs.cloudflare.com; frame-src https://www.google.com https://recaptcha.google.com;");
```

### 10.3 Rate limiting (pendiente implementar)

```php
function checkLoginRateLimit(mysqli $conn, string $ip): bool {
    $window = 15 * 60; // 15 minutos
    $max_attempts = 5;
    $since = date('Y-m-d H:i:s', time() - $window);
    
    $stmt = $conn->prepare(
        "SELECT COUNT(*) as attempts FROM LoginAttempts 
         WHERE ip = ? AND attempted_at > ?"
    );
    $stmt->bind_param("ss", $ip, $since);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    
    return $result['attempts'] < $max_attempts;
}
```

---

## 11. Edge Cases

### 11.1 Casos de borde críticos

| Caso | Situación | Comportamiento esperado |
|------|-----------|------------------------|
| Admin sin teléfono | Administrador registrado sin número de teléfono | Forzar opción de email OTP; no iniciar Firebase Phone |
| Token OTP expirado | Usuario tarda >10 min en ingresar OTP | Mostrar "Código expirado, solicita uno nuevo"; ofrecer reenvío |
| Sesión temporal huérfana | Admin cierra pestaña durante 2FA | Al volver a login.php, limpiar variables temp_* y reiniciar |
| Múltiples tabs abiertas | Usuario abre 2 tabs durante 2FA | Segunda tab detecta temp session y redirige a verificacion_2fa.php |
| Registro con mismo email, diferente capitalización | "ADMIN@EMPRESA.COM" vs "admin@empresa.com" | Normalizar email a minúsculas antes de guardar e consultar |
| Contraseña con caracteres especiales en SQL | Password contiene `'` o `"` | Prepared statements lo manejan; no necesita escape manual |
| Firebase SDK no carga (sin internet) | Falla CDN de Firebase | Mostrar mensaje amable; deshabilitar login con reCAPTCHA |
| Session cookie robada | Ataque de session hijacking | Regenerar session_id() después de login exitoso |

### 11.2 Comportamiento en navegador con JS deshabilitado

- La verificación de reCAPTCHA requiere JavaScript
- Con JS deshabilitado: mostrar mensaje explicando el requerimiento
- Alternativa: formulario de fallback sin reCAPTCHA (solo para entorno local)

### 11.3 Consideraciones de timezone

```php
// Siempre usar UTC para timestamps de tokens
$expiry = gmdate('Y-m-d H:i:s', strtotime('+1 hour'));

// Para comparar expiración
if (strtotime($row['expiry']) < time()) {
    // token expirado
}
```

---

## 12. APIs del Módulo

### POST /guardar_sesion_temp.php

**Propósito**: Guardar datos temporales de sesión desde JavaScript (durante 2FA)

**Request**:
```json
{ "user_id": 1, "role": "Administrador", "nombre": "Admin" }
```

**Response**:
```json
{ "success": true }
```

**Validaciones**: verificar que temp_user_id ya existe en sesión (no se puede crear sesión temporal vía AJAX directamente)

---

### POST /guardar_codigo.php

**Propósito**: Guardar OTP generado en sesión

**Request**: `{ "codigo": "123456" }`

**Response**: `{ "success": true }`

**Validaciones**: verificar que temp_user_id existe en sesión

---

### POST /enviar_correo_confirmacion.php

**Propósito**: Enviar OTP por email (2FA alternativo)

**Request**: `{ "email": "admin@empresa.com" }`

**Response**:
```json
{ "success": true, "message": "Código enviado a tu correo" }
```

**Validaciones**:
- Verificar que temp_user_id existe en sesión
- Verificar que el email coincide con temp_email de sesión
- Rate limit: máx 3 envíos en 10 minutos

---

### POST /update_session.php

**Propósito**: Promover sesión temporal a completa después de 2FA exitoso

**Request**: `{ "action": "promote_session" }`

**Response**: `{ "success": true, "redirect": "index.php" }`

**Validaciones**:
- Verificar que temp_user_id existe en sesión
- Verificar que la verificación Firebase fue exitosa (token Firebase en request)

---

## 13. Schema de BD Relacionado

### Tabla: Usuarios (campos de auth)
```sql
CREATE TABLE `Usuarios` (
  `id_usuario`          INT(11) AUTO_INCREMENT PRIMARY KEY,
  `nombre`              VARCHAR(100),
  `correo_electronico`  VARCHAR(100) UNIQUE,
  `contrasena`          VARCHAR(255),       -- bcrypt hash
  `rol`                 ENUM('Administrador','Usuario','Empleado'),
  `estado`              ENUM('Activo','Inactivo','Pendiente'),
  `telefono`            VARCHAR(20),        -- formato: +50312345678
  `reset_token`         VARCHAR(64),        -- token de recuperación
  `reset_token_expiry`  DATETIME,           -- expiración del token
  `email_verified`      TINYINT(1) DEFAULT 0,
  `fecha_creacion`      DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

### Tabla: IntentosInyeccionSQL
```sql
CREATE TABLE `IntentosInyeccionSQL` (
  `id`       INT AUTO_INCREMENT PRIMARY KEY,
  `intento`  TEXT,
  `ip`       VARCHAR(45),
  `fecha`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

### Tabla: LoginAttempts (pendiente crear)
```sql
CREATE TABLE `LoginAttempts` (
  `id`           INT AUTO_INCREMENT PRIMARY KEY,
  `email`        VARCHAR(100),
  `ip`           VARCHAR(45),
  `success`      TINYINT(1) DEFAULT 0,
  `attempted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_ip_time (ip, attempted_at),
  INDEX idx_email_time (email, attempted_at)
) ENGINE=InnoDB;
```

---

## 14. Organización Interna de Código

### 14.1 Estructura recomendada para login.php

```
Sección 1: require + session (5 líneas)
Sección 2: procesamiento POST — login (50 líneas)
  - detección SQL injection
  - query usuario
  - password_verify
  - creación de sesión (normal o temporal)
  - redirect
Sección 3: include header (1 línea)
Sección 4: HTML del formulario (60 líneas)
  - logo
  - mensaje de error
  - campos email + password
  - recaptcha container
  - botón submit
Sección 5: scripts Firebase (40 líneas)
  - initializeRecaptcha
  - onSubmit
Sección 6: include footer (1 línea)

TOTAL: ~160 líneas
```

### 14.2 Funciones que deben estar en helpers

```php
// functions/auth.php
function requireAuth(): void { ... }
function requireRole(string $role): void { ... }
function requireRoles(array $roles): void { ... }
function promoteSession(): void { ... }
function loadUserPreferences(int $userId): void { ... }
function detectSQLInjection(mysqli $conn, string $input, string $ip): bool { ... }
function generateOTP(int $digits = 6): string { ... }
function generateResetToken(): string { ... }
function validatePassword(string $password): array { ... }
function validateEmail(string $email): bool { ... }
function validatePhone(string $phone): bool { ... }
```

---

## 15. Quality Requirements

### 15.1 Métricas específicas del módulo Auth

| Métrica | Límite |
|---------|--------|
| Tiempo de login (sin 2FA) | < 500ms |
| Tiempo de login completo (con 2FA SMS) | < 30s |
| Tiempo de envío de email | < 5s |
| Máx. intentos de login fallidos (rate limit) | 5 por 15 min por IP |
| Expiración de token de recuperación | 1 hora |
| Expiración de OTP email | 10 minutos |
| Expiración de sesión por inactividad | 60 minutos |

### 15.2 Cobertura de validación

```
- Todos los campos del formulario de registro: validación en PHP (server-side)
- Email: format + unicidad
- Contraseña: complejidad (8+ chars, mayúsc, minúsc, número, especial)
- Teléfono: formato internacional
- Outputs de BD: htmlspecialchars() antes de renderizar
```

---

## 16. Testing Scenarios

### Happy path
- [ ] Login exitoso como Empleado → sesión establecida correctamente
- [ ] Login exitoso como Administrador → 2FA por SMS completa
- [ ] Login exitoso como Administrador → 2FA por email completa
- [ ] Registro nuevo usuario → email de verificación recibido
- [ ] Verificar email via link → cuenta activada
- [ ] Recuperar contraseña → email recibido → nueva contraseña guardada
- [ ] Logout → sesión destruida → redirige a login

### Error paths
- [ ] Login con contraseña incorrecta → mensaje de error, sin sesión
- [ ] Login con cuenta inactiva → mensaje de error genérico
- [ ] Login con email inexistente → mensaje de error genérico
- [ ] 2FA con código SMS incorrecto → error, ofrecer reintento
- [ ] 2FA con código OTP expirado → error, ofrecer reenvío
- [ ] Registro con email duplicado → mensaje de error claro
- [ ] Registro con contraseña débil → validación detallada
- [ ] Token de recuperación expirado → error con link a solicitar nuevo

### Seguridad
- [ ] Login con payload SQL injection → registrado en BD, bloqueado
- [ ] Acceso directo a `administrar_usuarios.php` sin sesión → redirect login
- [ ] Acceso directo a `administrar_usuarios.php` como Empleado → redirect index
- [ ] Manipulación de cookie de sesión → sesión inválida
- [ ] Reenvío de OTP 4+ veces → rate limit activado

### Edge cases
- [ ] Registro con email en mayúsculas → normalizado a minúsculas
- [ ] Login con múltiples tabs simultáneas → comportamiento predecible
- [ ] Cerrar tab durante 2FA → sesión temporal limpiada al volver a login
- [ ] Sesión expirada durante operación → redirect a login con mensaje

---

*Spec generada: 2026-04-24T21:19:11Z*
