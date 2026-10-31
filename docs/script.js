/**
 * Lunera - Landing Page Interactive Logic
 * Signature Celestial Midnight & Pastel Theme
 */

const LUNERA_REPO = "valynlove/lunera";
const APP_VERSION = "1.10.0";

// Unified Signature Theme - Permanent Dark Celestial Midnight Palette
function lockSignatureTheme() {
  document.documentElement.setAttribute("data-theme", "dark");
  localStorage.setItem("lunera_theme", "dark");
}

// Showcase Tabs Data
const showcaseData = {
  beranda: {
    title: "Intuitive Daily Rhythm & Dose Counter",
    desc: "Everything you need at a glance. Check your upcoming dose countdown, recent injection sites, estimated hormone levels, and quick logging shortcuts.",
    bullets: [
      "Live countdown timer to your next scheduled hormone dose",
      "Immediate one-tap 'Take Dose' and 'Skip Dose' quick actions",
      "Overview of today's mood, physical transitions, and stock alerts"
    ]
  },
  levels: {
    title: "Interactive Pharmacokinetic Simulation",
    desc: "Visualize your estimated serum hormone concentration over time based on validated medical PK models, with custom target range overlays.",
    bullets: [
      "Multi-compartment decay curves for Valerate, Cypionate, Enanthate & more",
      "Target therapeutic zone visualization (trough & peak indicators)",
      "Calibration support using actual blood test lab results"
    ]
  },
  jadwal: {
    title: "Visual Cycle Calendar & History",
    desc: "Inspect past administration logs and forecast future injection cycles with an interactive full-month calendar.",
    bullets: [
      "Color-coded day badges for taken, upcoming, and skipped doses",
      "Exact intake timestamps and injection site records",
      "Rolling dose intervals with cycle forecast months ahead"
    ]
  },
  jurnal: {
    title: "Transition Journal & Supply Tracker",
    desc: "Document physical transformations and emotional well-being alongside automatic medical supply inventory management.",
    bullets: [
      "Categorized daily mood scoring and observation notes",
      "Automatic deduction of vials, syringes, and needles on dose intake",
      "Low inventory warnings before essential supplies run out"
    ]
  }
};

function setupShowcaseTabs() {
  const tabs = document.querySelectorAll(".showcase-tab-btn");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      tab.classList.add("active");

      const key = tab.getAttribute("data-tab");
      const data = showcaseData[key];
      if (data) {
        const titleEl = document.getElementById("showcase-title");
        const descEl = document.getElementById("showcase-desc");
        const listEl = document.getElementById("showcase-bullets");

        if (titleEl) titleEl.textContent = data.title;
        if (descEl) descEl.textContent = data.desc;
        if (listEl) {
          listEl.innerHTML = "";
          data.bullets.forEach(b => {
            const li = document.createElement("li");
            li.innerHTML = '<span class="check-icon">✓</span> ' + b;
            listEl.appendChild(li);
          });
        }
      }
    });
  });
}

// Mobile Navigation Toggle
function setupMobileNav() {
  const toggle = document.getElementById("mobile-toggle");
  const nav = document.getElementById("nav-links");
  if (toggle && nav) {
    toggle.addEventListener("click", () => {
      nav.classList.toggle("active");
    });
    nav.querySelectorAll("a").forEach(link => {
      link.addEventListener("click", () => {
        nav.classList.remove("active");
      });
    });
  }
}

// Fetch latest release tag from GitHub API to keep web badges dynamically up-to-date
function fetchLatestReleaseVersion() {
  fetch(`https://api.github.com/repos/${LUNERA_REPO}/releases/latest`)
    .then(res => {
      if (!res.ok) throw new Error("GitHub API unavailable or rate-limited");
      return res.json();
    })
    .then(data => {
      if (data.tag_name) {
        const tag = data.tag_name;
        document.querySelectorAll(".app-version-tag").forEach(el => {
          el.textContent = tag;
        });
        const heroDownloadText = document.getElementById("hero-download-text");
        if (heroDownloadText) {
          heroDownloadText.textContent = `Download APK (${tag})`;
        }
        const specsVersion = document.getElementById("specs-version-val");
        if (specsVersion) {
          specsVersion.textContent = `${tag} (Release)`;
        }

        // Update APK asset links if found
        const apkAsset = data.assets?.find(a => a.name.endsWith('.apk'));
        if (apkAsset) {
          document.querySelectorAll(".apk-download-btn").forEach(link => {
            link.href = apkAsset.browser_download_url;
          });
        }
      }
    })
    .catch(() => {
      // Graceful fallback to baked-in APP_VERSION
    });
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  // Lock to Lunera's signature Midnight & Pastel palette
  lockSignatureTheme();

  setupShowcaseTabs();
  setupMobileNav();
  fetchLatestReleaseVersion();
});
