        </div><!-- /page-content -->
    </div><!-- /body-wrapper -->
</div><!-- /layout -->

<script>
(function () {
    /* ── Sidebar toggle ── */
    var sidebar = document.getElementById('sidebar');
    var overlay = document.getElementById('sidebarOverlay');
    var toggle  = document.getElementById('sidebarToggle');

    if (!sidebar) return;

    function openSidebar() {
        sidebar.classList.add('open');
        if (overlay) overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }

    function closeSidebar() {
        sidebar.classList.remove('open');
        if (overlay) overlay.classList.remove('active');
        document.body.style.overflow = '';
    }

    if (toggle) {
        toggle.addEventListener('click', function (e) {
            e.stopPropagation();
            sidebar.classList.contains('open') ? closeSidebar() : openSidebar();
        });
    }

    if (overlay) {
        overlay.addEventListener('click', closeSidebar);
    }

    window.addEventListener('resize', function () {
        if (window.innerWidth > 1280) closeSidebar();
    });
})();

(function () {
    /* ── Dark Mode toggle ── */
    var htmlEl   = document.getElementById('html-root');
    var btn      = document.getElementById('themeToggle');
    var forceDark = !!(window.APP_UI_SETTINGS && window.APP_UI_SETTINGS.forceDarkMode);

    // Apply saved preference on load (already done inline, but ensures sync)
    function applyTheme(dark) {
        if (forceDark) dark = true;
        if (dark) {
            htmlEl.classList.add('dark');
            localStorage.setItem('theme', 'dark');
        } else {
            htmlEl.classList.remove('dark');
            localStorage.setItem('theme', 'light');
        }
    }

    if (btn && htmlEl) {
        if (forceDark) {
            btn.setAttribute('title', 'Modo oscuro permanente activo');
            btn.setAttribute('aria-label', 'Modo oscuro permanente activo');
            btn.style.opacity = '0.72';
        }
        btn.addEventListener('click', function () {
            if (forceDark) {
                applyTheme(true);
                return;
            }
            var isDark = htmlEl.classList.contains('dark');
            applyTheme(!isDark);
        });
    }

    // Respect system preference when no saved theme
    if (!forceDark && !localStorage.getItem('theme')) {
        var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
        if (prefersDark) applyTheme(true);
    }

    if (forceDark) {
        applyTheme(true);
    }

    // Listen for system theme changes
    if (!forceDark && window.matchMedia) {
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function (e) {
            if (!localStorage.getItem('theme')) {
                applyTheme(e.matches);
            }
        });
    }
})();

/* ── Global banner image sync (all modules) ── */
(function () {
    var bannerImage = window.APP_UI_SETTINGS && window.APP_UI_SETTINGS.bannerImage
        ? String(window.APP_UI_SETTINGS.bannerImage)
        : '';
    var bannerVersion = window.APP_UI_SETTINGS && window.APP_UI_SETTINGS.bannerVersion
        ? String(window.APP_UI_SETTINGS.bannerVersion)
        : '';
    if (!bannerImage) return;
    var bannerSrc = bannerImage;
    if (bannerVersion) {
        bannerSrc += (bannerImage.indexOf('?') === -1 ? '?v=' : '&v=') + encodeURIComponent(bannerVersion);
    }

    document.querySelectorAll('.page-banner .page-banner-img, .dashboard-hero .page-banner-img').forEach(function (img) {
        if (img && img.getAttribute('src') !== bannerSrc) {
            img.setAttribute('src', bannerSrc);
        }
    });
})();
/* ── Toast notifications ── */
(function () {
    var iconMap = {
        success: '<i class="fas fa-circle-check" style="color:var(--success);font-size:16px;flex-shrink:0;"></i>',
        error:   '<i class="fas fa-circle-xmark" style="color:var(--error);font-size:16px;flex-shrink:0;"></i>',
        warning: '<i class="fas fa-triangle-exclamation" style="color:var(--warning);font-size:16px;flex-shrink:0;"></i>',
        info:    '<i class="fas fa-circle-info" style="color:var(--primary);font-size:16px;flex-shrink:0;"></i>'
    };

    window.showToast = function (message, type) {
        type = type || 'info';
        var container = document.getElementById('toast-container');
        if (!container) {
            container = document.createElement('div');
            container.id = 'toast-container';
            container.className = 'toast-container';
            document.body.appendChild(container);
        }
        var toast = document.createElement('div');
        toast.className = 'toast ' + type;
        toast.innerHTML = (iconMap[type] || iconMap.info) + '<span>' + message + '</span>';
        container.appendChild(toast);
        setTimeout(function () {
            toast.style.opacity = '0';
            toast.style.transform = 'translateX(24px)';
            toast.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
            setTimeout(function () { toast.remove(); }, 320);
        }, 3500);
    };
})();


/* ── Global modal helpers (for pages that don't define them) ── */
if (typeof openModal === 'undefined') {
    window.openModal = function (id) {
        var m = document.getElementById(id);
        if (m) {
            m.style.display = 'flex';
            var first = m.querySelector('input:not([type=hidden]), select, textarea');
            if (first) first.focus();
        }
    };
}
if (typeof closeModal === 'undefined') {
    window.closeModal = function (id) {
        var m = document.getElementById(id);
        if (m) m.style.display = 'none';
    };
}

/* Close modal on overlay click */
document.addEventListener('click', function (e) {
    if (e.target && e.target.classList && e.target.classList.contains('modal')) {
        e.target.style.display = 'none';
    }
});

/* Close modal on Escape key */
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        document.querySelectorAll('.modal').forEach(function (m) {
            m.style.display = 'none';
        });
    }
});
</script>

</body>
</html>
