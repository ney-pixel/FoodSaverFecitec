////////////////////////////////////////////////////
// 🎬 ANIMAÇÕES (FADE IN / OUT)
////////////////////////////////////////////////////

// Fade-in ao carregar
window.addEventListener("load", () => {
  document.body.classList.add("fade-in");
});

// Fade-out em navegação (ignora âncoras internas "#")
document.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", function (e) {
    const destino = this.getAttribute("href");

    if (destino && !destino.startsWith("#")) {
      e.preventDefault();

      document.body.classList.add("fade-out");

      setTimeout(() => {
        window.location.href = destino;
      }, 150);
    }
  });
});
