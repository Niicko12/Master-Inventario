        <!-- Page content ends here -->
    </main><!-- /.main-content -->
</div><!-- /.layout -->

<script src="js/ui-feedback.js"></script>

<!-- Mobile sidebar toggle -->
<script>
(function () {
    var sidebar = document.getElementById('sidebar');
    var toggle  = document.getElementById('sidebarToggle');
    if (!sidebar || !toggle) return;

    toggle.addEventListener('click', function () {
        sidebar.classList.toggle('open');
    });

    // Close sidebar when clicking outside on mobile
    document.addEventListener('click', function (e) {
        if (window.innerWidth <= 768 &&
            sidebar.classList.contains('open') &&
            !sidebar.contains(e.target) &&
            e.target !== toggle &&
            !toggle.contains(e.target)) {
            sidebar.classList.remove('open');
        }
    });
})();
</script>

<?php if (isset($extra_js)): ?>
    <?= $extra_js ?>
<?php endif; ?>
</body>
</html>
