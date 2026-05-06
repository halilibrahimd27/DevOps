// DevOps Notebook — küçük UX yardımcıları

// Mermaid diagram renkleri Material teması rengiyle uyumlu olsun
document.addEventListener("DOMContentLoaded", () => {
  if (window.mermaid) {
    const isDark = document.body.getAttribute("data-md-color-scheme") === "slate";
    mermaid.initialize({
      startOnLoad: true,
      theme: isDark ? "dark" : "default",
      flowchart: { useMaxWidth: true, htmlLabels: true, curve: "basis" },
      themeVariables: isDark
        ? { primaryColor: "#7e57c2", primaryBorderColor: "#5e35b1", lineColor: "#f4511e" }
        : { primaryColor: "#ede7f6", primaryBorderColor: "#5e35b1", lineColor: "#f4511e" }
    });
  }
});

// Kod bloğunda "Copy" butonuna basınca küçük confirm mesajı (Material zaten yapıyor;
// bu sadece guard).
(() => {
  const buttons = document.querySelectorAll(".md-clipboard");
  buttons.forEach((btn) => {
    btn.addEventListener("click", () => {
      btn.setAttribute("title", "Kopyalandı");
      setTimeout(() => btn.setAttribute("title", "Kopyala"), 1500);
    });
  });
})();
