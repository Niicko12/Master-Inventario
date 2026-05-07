/**
 * ui-feedback.js — Sistema de toasts y modales de confirmación
 * Reemplaza alert() / confirm() del navegador con UI oscura consistente
 */

// ── Toast system ──────────────────────────────────────────────────────────
function showToast(message, type) {
    type = type || 'info';

    const cfg = {
        success: { bg: 'rgba(52,211,153,0.12)',  border: 'rgba(52,211,153,0.35)',  text: '#34d399', icon: '✓' },
        error:   { bg: 'rgba(245,89,175,0.12)',  border: 'rgba(245,89,175,0.35)',  text: '#f559af', icon: '✕' },
        warning: { bg: 'rgba(255,170,0,0.12)',   border: 'rgba(255,170,0,0.35)',   text: '#ffaa00', icon: '⚠' },
        info:    { bg: 'rgba(58,215,232,0.12)',  border: 'rgba(58,215,232,0.35)',  text: '#3ad7e8', icon: 'ℹ' }
    };
    const c = cfg[type] || cfg.info;

    let container = document.getElementById('_toast_container');
    if (!container) {
        container = document.createElement('div');
        container.id = '_toast_container';
        Object.assign(container.style, {
            position: 'fixed', top: '20px', right: '20px',
            zIndex: '99999', display: 'flex',
            flexDirection: 'column', gap: '8px',
            pointerEvents: 'none'
        });
        document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    Object.assign(toast.style, {
        background: c.bg,
        border: '1px solid ' + c.border,
        color: c.text,
        padding: '12px 16px',
        borderRadius: '10px',
        fontSize: '14px',
        fontFamily: "'Inter', sans-serif",
        fontWeight: '500',
        display: 'flex',
        alignItems: 'center',
        gap: '10px',
        minWidth: '260px',
        maxWidth: '380px',
        backdropFilter: 'blur(10px)',
        boxShadow: '0 4px 24px rgba(0,0,0,0.45)',
        animation: 'slideIn 0.25s ease',
        pointerEvents: 'auto',
        cursor: 'pointer',
        userSelect: 'none'
    });

    const icon = document.createElement('span');
    icon.textContent = c.icon;
    icon.style.cssText = 'font-size:16px;flex-shrink:0;';

    const text = document.createElement('span');
    text.textContent = message;
    text.style.lineHeight = '1.4';

    toast.appendChild(icon);
    toast.appendChild(text);
    container.appendChild(toast);

    const remove = function() {
        toast.style.animation = 'slideOut 0.25s ease forwards';
        setTimeout(function() { toast.remove(); }, 260);
    };
    toast.addEventListener('click', remove);

    const timer = setTimeout(remove, 4500);
    toast.addEventListener('click', function() { clearTimeout(timer); });
}

// ── Confirm modal ─────────────────────────────────────────────────────────
function confirmAction(message, onConfirm) {
    const overlay = document.createElement('div');
    Object.assign(overlay.style, {
        position: 'fixed', inset: '0',
        background: 'rgba(0,0,0,0.65)',
        zIndex: '100000',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        backdropFilter: 'blur(4px)',
        fontFamily: "'Inter', sans-serif"
    });

    const box = document.createElement('div');
    Object.assign(box.style, {
        background: '#141929',
        border: '1px solid rgba(255,255,255,0.08)',
        borderRadius: '16px',
        padding: '28px',
        maxWidth: '400px',
        width: '90%',
        boxShadow: '0 24px 60px rgba(0,0,0,0.6)',
        animation: 'modalIn 0.2s ease'
    });

    box.innerHTML = [
        '<div style="display:flex;align-items:center;gap:12px;margin-bottom:14px;">',
          '<div style="width:40px;height:40px;border-radius:10px;background:rgba(245,89,175,0.15);display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;">⚠</div>',
          '<h3 style="color:#e8eaf6;font-size:16px;font-weight:600;margin:0;">Confirmar acción</h3>',
        '</div>',
        '<p style="color:#8892b0;font-size:14px;margin-bottom:24px;line-height:1.6;">' + message + '</p>',
        '<div style="display:flex;gap:10px;justify-content:flex-end;">',
          '<button id="_cfm_cancel" style="padding:8px 20px;border-radius:8px;border:1px solid rgba(255,255,255,0.1);background:rgba(255,255,255,0.06);color:#8892b0;cursor:pointer;font-size:14px;font-family:inherit;">Cancelar</button>',
          '<button id="_cfm_ok" style="padding:8px 20px;border-radius:8px;border:none;background:#f559af;color:#fff;cursor:pointer;font-size:14px;font-weight:600;font-family:inherit;">Confirmar</button>',
        '</div>'
    ].join('');

    overlay.appendChild(box);
    document.body.appendChild(overlay);

    const close = function() { overlay.remove(); };

    box.querySelector('#_cfm_cancel').addEventListener('click', close);
    overlay.addEventListener('click', function(e) { if (e.target === overlay) close(); });
    box.querySelector('#_cfm_ok').addEventListener('click', function() {
        close();
        onConfirm();
    });

    // Escape key
    const escHandler = function(e) {
        if (e.key === 'Escape') { close(); document.removeEventListener('keydown', escHandler); }
    };
    document.addEventListener('keydown', escHandler);
}

// ── Delete helper (for GET-delete links) ─────────────────────────────────
function confirmDelete(event, url, productName) {
    event.preventDefault();
    confirmAction(
        '¿Eliminar <strong style="color:#e8eaf6;">' + (productName || 'este elemento') + '</strong>? Esta acción no se puede deshacer.',
        function() { window.location.href = url; }
    );
}

// ── Auto-show toasts from PHP flash ──────────────────────────────────────
document.addEventListener('DOMContentLoaded', function() {
    if (typeof _flashMessage !== 'undefined' && _flashMessage) {
        showToast(_flashMessage, _flashType || 'info');
    }
});
