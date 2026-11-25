/**
 * Lunera — Landing Page Interactive Logic
 * Signature Eternal Dusk Theme
 */

const LUNERA_REPO = "valynlove/lunera";
const APP_VERSION = "2.2.41";

// Helper to update button label text without stripping SVG icon or shimmer span
function setButtonLabel(button, text) {
  if (!button) return;
  const labelSpan = button.querySelector("span:not(.btn-shimmer)");
  if (labelSpan) {
    labelSpan.textContent = text;
  }
}

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

        const heroDownloadBtn = document.getElementById("hero-download-btn");
        if (heroDownloadBtn) {
          setButtonLabel(heroDownloadBtn, `Download APK (${tag})`);
        }

        const ctaDownloadBtn = document.getElementById("cta-download-btn");
        if (ctaDownloadBtn) {
          setButtonLabel(ctaDownloadBtn, `Download APK (${tag})`);
        }

        // Point to direct arm64-v8a APK asset link if explicitly found
        const apkAsset =
          data.assets?.find(a => a.name === "Lunera.apk") ||
          data.assets?.find(a => a.name.endsWith("_arm64-v8a.apk")) ||
          data.assets?.find(a => a.name.endsWith(".apk"));
        const downloadUrl = apkAsset ? apkAsset.browser_download_url : directApkUrl;
        document.querySelectorAll(".apk-download-btn").forEach(link => {
          link.href = downloadUrl;
        });
      }
    })
    .catch(() => {
      // Graceful fallback to baked-in APP_VERSION and direct APK link
      const heroDownloadBtn = document.getElementById("hero-download-btn");
      if (heroDownloadBtn) {
        setButtonLabel(heroDownloadBtn, `Download APK (v${APP_VERSION})`);
      }
      const ctaDownloadBtn = document.getElementById("cta-download-btn");
      if (ctaDownloadBtn) {
        setButtonLabel(ctaDownloadBtn, `Download APK (v${APP_VERSION})`);
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

// Setup interactive Multi-Route Therapy Switcher
function setupRouteSwitcher() {
  const routePills = document.querySelectorAll(".route-pill");
  if (!routePills.length) return;

  const routeData = {
    inj: {
      name: "Estradiol Valerate",
      ico: "💉",
      amount: "4 mg",
      schedule: "Every 7 days",
      site: "next: Right thigh",
      dialNum: "1",
      dialSub: "1 day left",
      levelTitle: "Estimated Estradiol",
      levelNum: "185",
      levelUnit: "pg/mL",
      levelSub: "steady-state",
      levelBadge: "In Range",
      dotCx: 155,
      dotCy: 30
    },
    patch: {
      name: "Climara Patch",
      ico: "🩹",
      amount: "100 µg",
      schedule: "Twice weekly (3.5 d)",
      site: "next: Lower abdomen",
      dialNum: "12",
      dialSub: "12 hours left",
      levelTitle: "Estimated Estradiol",
      levelNum: "145",
      levelUnit: "pg/mL",
      levelSub: "transdermal steady",
      levelBadge: "In Range",
      dotCx: 140,
      dotCy: 36
    },
    gel: {
      name: "Oestrogel (Gel)",
      ico: "🧴",
      amount: "1.5 mg (2 pumps)",
      schedule: "Daily at 08:00",
      site: "next: Inner arm / thigh",
      dialNum: "✓",
      dialSub: "Applied today",
      levelTitle: "Estimated Estradiol",
      levelNum: "125",
      levelUnit: "pg/mL",
      levelSub: "daily diurnal peak",
      levelBadge: "In Range",
      dotCx: 120,
      dotCy: 40
    },
    oral: {
      name: "Estradiol Micronized",
      ico: "💊",
      amount: "2 mg",
      schedule: "Twice daily (12h)",
      site: "next: Under tongue (SL)",
      dialNum: "4",
      dialSub: "Due in 4h",
      levelTitle: "Estimated Estradiol",
      levelNum: "160",
      levelUnit: "pg/mL",
      levelSub: "biphasic absorption",
      levelBadge: "In Range",
      dotCx: 130,
      dotCy: 32
    }
  };

  routePills.forEach(pill => {
    pill.addEventListener("click", () => {
      const routeKey = pill.getAttribute("data-route");
      const data = routeData[routeKey];
      if (!data) return;

      routePills.forEach(p => {
        p.classList.remove("active");
        p.setAttribute("aria-selected", "false");
      });
      pill.classList.add("active");
      pill.setAttribute("aria-selected", "true");

      // Update phone mockup elements
      const nameEl = document.getElementById("mockup-therapy-name");
      if (nameEl) nameEl.textContent = data.name;

      const icoEl = document.getElementById("mockup-dose-ico");
      if (icoEl) icoEl.textContent = data.ico;

      const amtEl = document.getElementById("mockup-dose-amount");
      if (amtEl) amtEl.textContent = data.amount;

      const schedEl = document.getElementById("mockup-dose-schedule");
      if (schedEl) schedEl.textContent = data.schedule;

      const siteEl = document.getElementById("mockup-dose-site");
      if (siteEl) siteEl.textContent = data.site;

      const dialNumEl = document.getElementById("mockup-dial-num");
      if (dialNumEl) dialNumEl.textContent = data.dialNum;

      const dialSubEl = document.getElementById("mockup-dial-sub");
      if (dialSubEl) dialSubEl.textContent = data.dialSub;

      // Update phone mockup B levels card
      const levelTitleEl = document.getElementById("mockup-level-title");
      if (levelTitleEl) levelTitleEl.textContent = data.levelTitle;

      const levelNumEl = document.getElementById("mockup-level-num");
      if (levelNumEl) levelNumEl.textContent = data.levelNum;

      const levelSubEl = document.getElementById("mockup-level-sub");
      if (levelSubEl) levelSubEl.textContent = data.levelSub;

      const levelBadgeEl = document.getElementById("mockup-level-badge");
      if (levelBadgeEl) levelBadgeEl.textContent = data.levelBadge;

      const chartDot = document.getElementById("mockup-chart-dot");
      if (chartDot) {
        chartDot.setAttribute("cx", data.dotCx);
        chartDot.setAttribute("cy", data.dotCy);
      }

      const liveStatus = document.getElementById("route-live-status");
      if (liveStatus) {
        liveStatus.textContent = `Selected ${data.name}: ${data.amount}, ${data.schedule}, estimated ${data.levelNum} ${data.levelUnit}.`;
      }
    });
  });
}

// Setup interactive 7-Day Pharmacokinetic Timeline Scrubber
function setupCycleScrubber() {
  const slider = document.getElementById("cycle-scrubber-range");
  if (!slider) return;

  const ticks = document.querySelectorAll(".scrubber-ticks-row .tick");
  const readout = document.getElementById("scrubber-day-readout");
  const stageBadge = document.getElementById("scrubber-stage-badge");
  const metricNum = document.getElementById("scrubber-metric-num");
  const metricBadge = document.getElementById("scrubber-metric-badge");
  const hintText = document.getElementById("scrubber-hint-text");
  const chartDot = document.getElementById("bento-scrubber-dot");

  const cycleDays = [
    {
      day: 0,
      readout: "Day 0 of 7 · Dose Day",
      stage: "💉 Dose Administered",
      metric: "240",
      badge: "In Therapeutic Target",
      badgeClass: "in-range",
      dotX: 20,
      dotY: 46,
      hint: "Ester depot administered. Systematic enzymatic absorption begins."
    },
    {
      day: 1,
      readout: "Day 1 of 7 · 6 Days Left",
      stage: "⚡ Peak Absorption",
      metric: "285",
      badge: "Peak Absorption Range",
      badgeClass: "in-range",
      dotX: 70,
      dotY: 20,
      hint: "Primary ester peak reached. Target systemic concentration fully active."
    },
    {
      day: 2,
      readout: "Day 2 of 7 · 5 Days Left",
      stage: "✨ Optimal Plateau",
      metric: "245",
      badge: "In Therapeutic Target",
      badgeClass: "in-range",
      dotX: 110,
      dotY: 22,
      hint: "Steady enzymatic cleavage into bio-identical 17β-estradiol."
    },
    {
      day: 3,
      readout: "Day 3 of 7 · 4 Days Left",
      stage: "✨ Steady State",
      metric: "215",
      badge: "In Therapeutic Target",
      badgeClass: "in-range",
      dotX: 145,
      dotY: 28,
      hint: "Therapeutic equilibrium plateau maintained across target tissues."
    },
    {
      day: 4,
      readout: "Day 4 of 7 · 3 Days Left",
      stage: "🌿 Mid-Cycle Zone",
      metric: "190",
      badge: "In Therapeutic Target",
      badgeClass: "in-range",
      dotX: 175,
      dotY: 34,
      hint: "Mid-cycle steady state. Sustained tissue rest rotation prevents lipohypertrophy."
    },
    {
      day: 5,
      readout: "Day 5 of 7 · 2 Days Left",
      stage: "📉 Pre-Trough Phase",
      metric: "165",
      badge: "In Therapeutic Target",
      badgeClass: "in-range",
      dotX: 200,
      dotY: 38,
      hint: "Approaching pre-trough concentration. Safe buffer window active."
    },
    {
      day: 6,
      readout: "Day 6 of 7 · 1 Day Left",
      stage: "🎯 Ideal Lab Window",
      metric: "138",
      badge: "Trough Testing Window (100–200)",
      badgeClass: "in-range",
      dotX: 235,
      dotY: 26,
      hint: "Ideal bloodwork draw window right before your next injection!"
    },
    {
      day: 7,
      readout: "Day 7 of 7 · Due Today",
      stage: "🔔 Dose Due Today",
      metric: "112",
      badge: "Trough Baseline",
      badgeClass: "trough",
      dotX: 270,
      dotY: 28,
      hint: "Cycle complete. Scheduled dose due today to maintain hormonal rhythm."
    }
  ];

  const updateScrubberState = (dayIndex) => {
    const data = cycleDays[dayIndex];
    if (!data) return;

    slider.value = dayIndex;

    if (readout) readout.textContent = data.readout;
    if (stageBadge) stageBadge.textContent = data.stage;
    if (metricNum) metricNum.innerHTML = `${data.metric} <small>pg/mL</small>`;
    if (metricBadge) metricBadge.textContent = data.badge;
    if (hintText) hintText.textContent = data.hint;

    if (chartDot) {
      chartDot.setAttribute("cx", data.dotX);
      chartDot.setAttribute("cy", data.dotY);
    }

    ticks.forEach(t => {
      const stepVal = parseInt(t.getAttribute("data-step"), 10);
      if (stepVal === dayIndex) {
        t.classList.add("active");
      } else {
        t.classList.remove("active");
      }
    });
  };

  slider.addEventListener("input", (e) => {
    const idx = parseInt(e.target.value, 10);
    updateScrubberState(idx);
  });

  ticks.forEach(t => {
    t.addEventListener("click", () => {
      const stepVal = parseInt(t.getAttribute("data-step"), 10);
      updateScrubberState(stepVal);
    });
  });

  // Initial call with day 6 (default)
  updateScrubberState(6);
}

// Setup responsive Mobile & Tablet Navigation Drawer
function setupMobileNav() {
  const toggleBtn = document.getElementById("nav-toggle");
  const drawer = document.getElementById("mobile-nav-drawer");
  const header = document.getElementById("site-header");
  if (!toggleBtn || !drawer) return;

  const setOpen = (isOpen) => {
    toggleBtn.setAttribute("aria-expanded", String(isOpen));
    if (isOpen) {
      drawer.removeAttribute("hidden");
      requestAnimationFrame(() => drawer.classList.add("open"));
    } else {
      drawer.classList.remove("open");
      drawer.setAttribute("hidden", "");
    }
  };

  toggleBtn.addEventListener("click", () => {
    const isExpanded = toggleBtn.getAttribute("aria-expanded") === "true";
    setOpen(!isExpanded);
  });

  drawer.querySelectorAll(".mobile-nav-link, .mobile-nav-cta").forEach(link => {
    link.addEventListener("click", () => setOpen(false));
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && toggleBtn.getAttribute("aria-expanded") === "true") {
      setOpen(false);
      toggleBtn.focus();
    }
  });

  document.addEventListener("click", (e) => {
    if (
      toggleBtn.getAttribute("aria-expanded") === "true" &&
      header &&
      !header.contains(e.target)
    ) {
      setOpen(false);
    }
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 900 && toggleBtn.getAttribute("aria-expanded") === "true") {
      setOpen(false);
    }
  }, { passive: true });
}

// Active Nav state on scroll and dynamic header elevation
function setupActiveNav() {
  const sections = document.querySelectorAll("header[id], section[id]");
  const navLinks = document.querySelectorAll("nav ul a, .mobile-nav-link");
  const header = document.getElementById("site-header");

  const onScroll = () => {
    // Header elevation on scroll
    if (header) {
      if (window.scrollY > 15) {
        header.classList.add("scrolled");
      } else {
        header.classList.remove("scrolled");
      }
    }

    // Active nav link highlight
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
  };

  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();
}

// Init on DOM ready
document.addEventListener("DOMContentLoaded", () => {
  fetchLatestReleaseVersion();
  updateMockupGreeting();
  setupMobileNav();
  setupActiveNav();
  setupRouteSwitcher();
  setupCycleScrubber();
});
