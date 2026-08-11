(() => {
  const root = document.documentElement;
  const themeToggle = document.querySelector("[data-theme-toggle]");

  if (themeToggle) {
    const themeLabel = themeToggle.querySelector("[data-theme-label]");
    const themeIcon = themeToggle.querySelector("[data-theme-icon]");
    const themeColor = document.querySelector("[data-theme-color]");

    const applyTheme = (theme, persist = false) => {
      const nextTheme = theme === "light" ? "light" : "dark";
      const nextChoice = nextTheme === "dark" ? "light" : "dark";

      root.dataset.theme = nextTheme;
      themeToggle.setAttribute("aria-label", `Switch to ${nextChoice} mode`);
      themeToggle.setAttribute("aria-pressed", String(nextTheme === "light"));

      if (themeLabel) themeLabel.textContent = nextChoice === "light" ? "Light" : "Dark";
      if (themeIcon) themeIcon.textContent = nextChoice === "light" ? "☀" : "☾";
      if (themeColor) {
        themeColor.content = nextTheme === "dark" ? "#121416" : "#f6f1e7";
      }

      if (persist) {
        try {
          localStorage.setItem("mica-theme", nextTheme);
        } catch (_) {
          // The visual state still works when storage is unavailable.
        }
      }
    };

    applyTheme(root.dataset.theme);

    themeToggle.addEventListener("click", () => {
      applyTheme(root.dataset.theme === "dark" ? "light" : "dark", true);
    });

    root.classList.add("theme-ready");

    window.addEventListener("storage", (event) => {
      if (event.key === "mica-theme" && (event.newValue === "dark" || event.newValue === "light")) {
        applyTheme(event.newValue);
      }
    });
  }

  const archive = document.querySelector("[data-content-filter]");

  if (archive) {
    const buttons = [...archive.querySelectorAll("[data-filter-value]")];
    const rows = [...archive.querySelectorAll("[data-filter-keys]")];
    const count = archive.querySelector("[data-visible-count]");

    const applyFilter = (value) => {
      let visible = 0;

      for (const row of rows) {
        const keys = (row.dataset.filterKeys || "").split(/\s+/);
        const show = value === "all" || keys.includes(value);
        row.hidden = !show;
        if (show) visible += 1;
      }

      for (const button of buttons) {
        button.setAttribute(
          "aria-pressed",
          String(button.dataset.filterValue === value),
        );
      }

      if (count) count.textContent = String(visible);
    };

    for (const button of buttons) {
      button.addEventListener("click", () => {
        applyFilter(button.dataset.filterValue || "all");
      });
    }
  }

  const mobileMenu = document.querySelector(".mobile-nav");
  if (mobileMenu) {
    mobileMenu.addEventListener("click", (event) => {
      if (event.target.closest("a")) mobileMenu.removeAttribute("open");
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") mobileMenu.removeAttribute("open");
    });
  }
})();
