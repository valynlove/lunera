/**
 * Lunera — Landing Page Interactive Logic
 * Signature Celestial Midnight & Pastel Theme
 */

const LUNERA_REPO = "valynlove/lunera";
const APP_VERSION = "1.11.9";

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

// Fetch latest release tag from GitHub API to keep download buttons dynamically up-to-date
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
          heroDownloadText.textContent = `Download for Android (${tag})`;
        }

        const specsVersion = document.getElementById("specs-version-val");
        if (specsVersion) {
          specsVersion.textContent = `${tag}`;
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
      const heroDownloadText = document.getElementById("hero-download-text");
      if (heroDownloadText) {
        heroDownloadText.textContent = `Download for Android (v${APP_VERSION})`;
      }
    });
}

// Format today's date in hero mockup
function updateMockupDate() {
  const dateEl = document.getElementById("phone-date-display");
  if (dateEl) {
    const now = new Date();
    const options = { weekday: 'long', month: 'long', day: 'numeric' };
    try {
      dateEl.textContent = now.toLocaleDateString('en-US', options);
    } catch (_) {}
  }
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  setupMobileNav();
  fetchLatestReleaseVersion();
  updateMockupDate();
});
