/* =========================
   Health & Backend Status
   ========================= */

async function loadHealth() {
  const res = await fetch("/health");
  const data = await res.json();

  document.getElementById("output").innerText =
    data.status === "ok" ? "✅ Backend is running" : "❌ Backend error";
}

/* =========================
   Add Sprout Modal
   ========================= */

function openAddSprout() {
  loadSeeds();
  document.getElementById("addSproutModal").style.display = "flex";
}

function closeAddSprout() {
  document.getElementById("addSproutModal").style.display = "none";
}

function handleAddSproutClick(event) {
  closeAddSprout();
}

/* =========================
   Seeds API
   ========================= */

async function loadSeeds() {
  const res = await fetch("/seeds");
  const seeds = await res.json();

  const select = document.getElementById("seedSelect");
  select.innerHTML = "";

  Object.entries(seeds).forEach(([seedId, seed]) => {
    const option = document.createElement("option");
    option.value = seedId;
    option.innerText = seed.name;

    select.appendChild(option);
  });
}

/* =========================
   Sprouts API
   ========================= */

async function createSprout() {
  const seedId = document.getElementById("seedSelect").value;

  await fetch("/sprouts", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      seed_id: seedId
    })
  });

  closeAddSprout();
  loadSprouts();
}

async function loadSprouts() {
  const res = await fetch("/sprouts");
  const sprouts = await res.json();

  const container = document.getElementById("sproutList");
  container.innerHTML = "";

  sprouts.forEach(sprout => {
    const div = document.createElement("div");
    div.className = "card";

    const title = document.createElement("strong");
    title.innerText = sprout.seed_name;
    div.appendChild(title);

    const phase = document.createElement("p");

    if (sprout.phase === "soaking") {
      const start = new Date(sprout.start_time);
      const now = new Date();

      const elapsedMs = now - start;
      const elapsedHours = elapsedMs / (1000 * 60 * 60);
      const required = sprout.soak_hours || 0;

      if (elapsedHours >= required) {
        phase.innerText = `Soaking complete (${required}h)`;
      } else {
        phase.innerText = `Soaking (${elapsedHours.toFixed(1)}h / ${required}h)`;
      }

      div.appendChild(phase);

      const button = document.createElement("button");
      button.innerText = "Done Soaking";

      button.onclick = async () => {
        await fetch(`/sprouts/${sprout.id}/done-soaking`, {
          method: "POST"
        });

        loadSprouts();
      };

        div.appendChild(button);
    } else {
      phase.innerText = `Phase: ${sprout.phase}`;
      div.appendChild(phase);
    }

    const rules = document.createElement("p");
    rules.innerText = `Soak: ${sprout.soak_hours}h | Grow: ${sprout.grow_days} days | Washes: ${sprout.washes_per_day}/day`;

    div.appendChild(rules);
    container.appendChild(div);
  });
}


/* =========================
   Calendar
   ========================= */

async function loadCalendar() {
  const res = await fetch("/calendar");
  const data = await res.json();

  const list = document.getElementById("calendar");
  list.innerHTML = "";

  data.forEach(item => {
    const div = document.createElement("div");
    div.className = "card";

    const time = document.createElement("strong");
    time.innerText = item.time;

    const event = document.createElement("p");
    event.innerText = item.event;
    event.style.margin = "5px 0 0 0";

    div.appendChild(time);
    div.appendChild(event);
    list.appendChild(div);
  });
}


/* =========================
   Clock
   ========================= */

function updateClock() {
  const now = new Date();
  const time = now.toLocaleTimeString();
  document.getElementById("clock").innerText = time;
}


/* =========================
   Settings Modal
   ========================= */

function openSettings() {
  loadSettings();
  document.getElementById("settingsModal").style.display = "flex";
}

function closeSettings() {
  document.getElementById("settingsModal").style.display = "none";
}

function handleModalClick(event) {
  closeSettings();
}


/* =========================
   Settings API
   ========================= */

async function saveSettings() {
  const username = document.getElementById("usernameInput").value;
  const theme = document.getElementById("themeInput").value;

  await fetch("/settings", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      username: username,
      theme: theme
    })
  });

  /* Apply theme immediately */
  document.body.className = theme;

  /* Close modal */
  closeSettings();
}

async function loadSettings() {
  const res = await fetch("/settings");
  const data = await res.json();

  const username = data.username || "";
  const theme = data.theme || "light";

  document.getElementById("usernameInput").value = username;
  document.getElementById("themeInput").value = theme;

  document.getElementById("welcome").innerText =
    username ? `Welcome, ${username}` : "";

  document.body.className = theme;

  console.log("settings loaded", data);
}


/* =========================
   Navigation / Views
   ========================= */

function showView(viewName) {
  document.getElementById("dashboardView").style.display = "none";
  document.getElementById("sproutsView").style.display = "none";

  if (viewName === "dashboard") {
    document.getElementById("dashboardView").style.display = "block";
  }

  if (viewName === "sprouts") {
    document.getElementById("sproutsView").style.display = "block";
    loadSprouts();
  }
}


/* =========================
   Sound Feedback
   ========================= */

function playClick() {
  const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  const oscillator = audioCtx.createOscillator();
  const gainNode = audioCtx.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(audioCtx.destination);

  oscillator.frequency.value = 700;
  gainNode.gain.value = 0.05;

  oscillator.start();
  oscillator.stop(audioCtx.currentTime + 0.04);
}


/* =========================
   App Initialization
   ========================= */

function init() {
  loadHealth();
  loadCalendar();
  loadSettings();
  updateClock();
  setInterval(updateClock, 1000);
}

window.onload = init;