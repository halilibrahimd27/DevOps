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

// Top nav (md-tabs): mouse wheel'i yatay scroll'a çevir + klavye ok tuşları
(() => {
  const initTabsScroll = () => {
    const tabs = document.querySelector(".md-tabs");
    if (!tabs || tabs.dataset.scrollInit === "1") return;
    tabs.dataset.scrollInit = "1";

    // Mouse wheel → yatay scroll (dikey hareketi yataya çevir)
    tabs.addEventListener("wheel", (e) => {
      if (e.deltaY === 0) return;
      // Sadece tabs taşıyorsa devral
      if (tabs.scrollWidth > tabs.clientWidth) {
        e.preventDefault();
        tabs.scrollLeft += e.deltaY;
      }
    }, { passive: false });

    // Aktif tab'a otomatik scroll (sayfa açıldığında görünür kılar)
    const active = tabs.querySelector(".md-tabs__link--active");
    if (active) {
      const rect = active.getBoundingClientRect();
      const tabsRect = tabs.getBoundingClientRect();
      if (rect.left < tabsRect.left || rect.right > tabsRect.right) {
        active.scrollIntoView({ block: "nearest", inline: "center", behavior: "smooth" });
      }
    }
  };

  // Material instant navigation kullanıyor — her sayfa değişiminde tekrar bind et
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initTabsScroll);
  } else {
    initTabsScroll();
  }
  // Material'ın instant navigation event'i
  document.addEventListener("DOMContentSwitch", initTabsScroll);
})();
