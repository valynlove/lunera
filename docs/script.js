/**
 * Lunera - Landing Page Interactive Logic
 */

const LUNERA_REPO = "valynlove/lunera";

// Automatically fetch latest release information from GitHub API if available
async function fetchLatestRelease() {
  try {
    const res = await fetch(`https://api.github.com/repos/${LUNERA_REPO}/releases/latest`);
    if (!res.ok) return;
    const data = await res.json();
    const tagName = data.tag_name || "v1.5.0";

    const badge = document.querySelector(".hero-badge");
    if (badge) {
      badge.textContent = `🌙 Personal Health & Therapy Tracker (${tagName})`;
    }

    // Look for APK asset in release
    const apkAsset = data.assets?.find(a => a.name.endsWith('.apk'));
    if (apkAsset) {
      const apkLinks = document.querySelectorAll(".apk-download-btn");
      apkLinks.forEach(link => {
        link.href = apkAsset.browser_download_url;
      });
    }

    // Look for Windows zip asset in release
    const winAsset = data.assets?.find(a => a.name.includes('windows') || a.name.endsWith('.zip'));
    if (winAsset) {
      const winLinks = document.querySelectorAll(".windows-download-btn");
      winLinks.forEach(link => {
        link.href = winAsset.browser_download_url;
      });
    }
  } catch (e) {
    console.debug("Could not fetch latest release info:", e);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  fetchLatestRelease();
});

