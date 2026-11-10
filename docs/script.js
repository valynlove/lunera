/**
 * Lunera — Landing Page Interactive Logic
 * Signature Celestial Midnight & Astral Gold Theme
 */

const LUNERA_REPO = "valynlove/lunera";
const APP_VERSION = "2.1.0";

// Fetch latest release tag and APK asset link from GitHub API
function fetchLatestReleaseVersion() {
  const directApkUrl = `https://github.com/${LUNERA_REPO}/releases/latest/download/Lunera.apk`;

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

        const heroDownloadText = document.getElementById("hero-download-btn");
        if (heroDownloadText) {
          heroDownloadText.textContent = `⬇ Download APK (${tag})`;
        }

        const ctaDownloadText = document.getElementById("cta-download-btn");
        if (ctaDownloadText) {
          ctaDownloadText.textContent = `⬇ Download APK (${tag})`;
        }

        // Point to direct APK asset link if explicitly found
        const apkAsset = data.assets?.find(a => a.name.endsWith('.apk'));
        const downloadUrl = apkAsset ? apkAsset.browser_download_url : directApkUrl;
        document.querySelectorAll(".apk-download-btn").forEach(link => {
          link.href = downloadUrl;
        });
      }
    })
    .catch(() => {
      // Graceful fallback to baked-in APP_VERSION and direct APK link
      const heroDownloadText = document.getElementById("hero-download-btn");
      if (heroDownloadText) {
        heroDownloadText.textContent = `⬇ Download APK (v${APP_VERSION})`;
      }
      document.querySelectorAll(".apk-download-btn").forEach(link => {
        link.href = directApkUrl;
      });
    });
}

// Set time-of-day greeting and live date in phone mockup
function updateMockupGreeting() {
  const now = new Date();

  const dateEl = document.getElementById("phone-date-display");
  if (dateEl) {
    const options = { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' };
    dateEl.textContent = now.toLocaleDateString('en-US', options);
  }

  const timeEl = document.getElementById("phone-time-display");
  if (timeEl) {
    const hours = now.getHours();
    const minutes = String(now.getMinutes()).padStart(2, '0');
    timeEl.textContent = `${hours}:${minutes}`;
  }

  const greetEl = document.getElementById("phone-greet-display");
  if (greetEl) {
    const hour = now.getHours();
    let greeting = "Good evening,";
    if (hour < 12) {
      greeting = "Good morning,";
    } else if (hour < 17) {
      greeting = "Good afternoon,";
    }
    greetEl.textContent = greeting;
  }
}

// Active Nav state on scroll
function setupActiveNav() {
  const sections = document.querySelectorAll("header[id], section[id]");
  const navLinks = document.querySelectorAll("nav ul a");

  window.addEventListener("scroll", () => {
    let current = "home";
    sections.forEach(section => {
      const sectionTop = section.offsetTop - 140;
      if (window.scrollY >= sectionTop) {
        current = section.getAttribute("id");
      }
    });

    navLinks.forEach(link => {
      link.classList.remove("on");
      if (link.getAttribute("href") === `#${current}`) {
        link.classList.add("on");
      }
    });
  });
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  fetchLatestReleaseVersion();
  updateMockupGreeting();
  setupActiveNav();
});
