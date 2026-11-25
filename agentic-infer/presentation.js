(() => {
  "use strict";

  const slides = [...document.querySelectorAll(".slide")];
  const previous = document.getElementById("prev-button");
  const next = document.getElementById("next-button");
  const overview = document.getElementById("overview-button");
  const fullscreen = document.getElementById("fullscreen-button");
  const dialog = document.getElementById("toc");
  const toc = document.getElementById("toc-links");
  const announcement = document.getElementById("announcement");
  let current = 0;
  let overviewMode = false;

  function titleFor(slide) {
    return slide.querySelector("h1, h2").textContent;
  }

  slides.forEach((slide, index) => {
    if (index === 0 || slide.dataset.topic !== slides[index - 1].dataset.topic) {
      const heading = document.createElement("h3");
      heading.className = "toc-group";
      heading.textContent = slide.dataset.topic;
      toc.append(heading);
    }
    const link = document.createElement("a");
    link.href = `#${slide.id}`;
    const number = document.createElement("span");
    number.textContent = String(index + 1).padStart(2, "0");
    link.append(number, document.createTextNode(titleFor(slide)));
    link.addEventListener("click", (event) => {
      event.preventDefault();
      dialog.close();
      setOverview(false);
      show(index);
    });
    toc.append(link);
  });

  const tocLinks = [...toc.querySelectorAll("a")];

  function show(index, updateHash = true) {
    current = Math.max(0, Math.min(slides.length - 1, index));
    slides.forEach((slide, i) => {
      slide.classList.toggle("is-active", i === current);
      if (i === current) tocLinks[i].setAttribute("aria-current", "page");
      else tocLinks[i].removeAttribute("aria-current");
    });
    previous.disabled = current === 0;
    next.disabled = current === slides.length - 1;
    document.getElementById("page-number").textContent =
      `${String(current + 1).padStart(2, "0")} / ${slides.length}`;
    document.getElementById("topic").textContent = slides[current].dataset.topic;
    document.getElementById("progress").style.width = `${((current + 1) / slides.length) * 100}%`;
    announcement.textContent = `第 ${current + 1} 页，共 ${slides.length} 页。${titleFor(slides[current])}`;
    if (updateHash) history.replaceState(null, "", `#${slides[current].id}`);
    if (overviewMode) slides[current].scrollIntoView({ block: "start" });
    else slides[current].scrollTop = 0;
  }

  function setOverview(enabled) {
    overviewMode = enabled;
    document.body.classList.toggle("overview", enabled);
    overview.setAttribute("aria-pressed", String(enabled));
    overview.textContent = enabled ? "返回演示" : "总览";
    if (enabled) slides[current].scrollIntoView({ block: "start" });
    else window.scrollTo(0, 0);
  }

  async function toggleFullscreen() {
    try {
      if (document.fullscreenElement) await document.exitFullscreen();
      else await document.documentElement.requestFullscreen();
    } catch (error) {
      console.error("无法切换全屏：", error);
      announcement.textContent = "浏览器未允许全屏，请使用浏览器的全屏菜单。";
      window.alert("浏览器未允许全屏，请使用浏览器的全屏菜单。");
    }
  }

  function fromHash() {
    const index = slides.findIndex((slide) => `#${slide.id}` === location.hash);
    show(index < 0 ? 0 : index, false);
  }

  previous.addEventListener("click", () => show(current - 1));
  next.addEventListener("click", () => show(current + 1));
  overview.addEventListener("click", () => setOverview(!overviewMode));
  fullscreen.addEventListener("click", toggleFullscreen);
  document.getElementById("print-button").addEventListener("click", () => window.print());
  document.getElementById("toc-button").addEventListener("click", () => dialog.showModal());
  document.getElementById("close-toc").addEventListener("click", () => dialog.close());
  document.addEventListener("fullscreenchange", () => {
    fullscreen.textContent = document.fullscreenElement ? "退出全屏 ↙" : "全屏 ↗";
  });
  window.addEventListener("hashchange", fromHash);
  document.addEventListener("keydown", (event) => {
    if (event.ctrlKey || event.altKey || event.metaKey || dialog.open) return;
    if (event.target.closest("input, textarea, select, [contenteditable]")) return;
    const key = event.key.toLowerCase();
    if (key === " " && event.target.closest("a, button")) return;
    if (key === "o") {
      event.preventDefault();
      setOverview(!overviewMode);
    } else if (key === "f") {
      event.preventDefault();
      toggleFullscreen();
    } else if (key === "escape" && overviewMode) {
      setOverview(false);
    } else if (!overviewMode) {
      const destination = {
        arrowright: current + 1, pagedown: current + 1,
        arrowleft: current - 1, pageup: current - 1,
        home: 0, end: slides.length - 1,
        " ": current + (event.shiftKey ? -1 : 1),
      }[key];
      if (destination !== undefined) {
        event.preventDefault();
        show(destination);
      }
    }
  });

  document.body.classList.add("enhanced");
  document.querySelectorAll(".controls").forEach((control) => { control.hidden = false; });
  if (!document.fullscreenEnabled) fullscreen.hidden = true;
  fromHash();
})();
