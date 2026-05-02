
/* =========================
   API Helpers
   ========================= */

async function apiGet(path) {
  const res = await fetch(path);

  if (!res.ok) {
    throw new Error(`GET ${path} failed`);
  }

  return res.json();
}

async function apiPost(path, body = null) {
  const options = {
    method: "POST"
  };

  if (body) {
    options.headers = {
      "Content-Type": "application/json"
    };
    options.body = JSON.stringify(body);
  }

  const res = await fetch(path, options);

  if (!res.ok) {
    throw new Error(`POST ${path} failed`);
  }

  return res.json();
}

/* =========================
   Health & Backend Status
   ========================= */

async function loadHealth() {
  const data = await apiGet("/health");

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
  const seeds = await apiGet("/seeds");

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

function addParagraph(parent, text) {
  const p = document.createElement("p");
  p.innerText = text;
  parent.appendChild(p);

  return p;
}

async function createSprout() {
  const seedId = document.getElementById("seedSelect").value;

  await apiPost("/sprouts", { seed_id: seedId });

  closeAddSprout();
  loadSprouts();
}

async function markDoneSoaking(sproutId) {
  await apiPost(`/sprouts/${sproutId}/done-soaking`);
  loadSprouts();
}

async function markWashDone(sproutId) {
  await apiPost(`/sprouts/${sproutId}/wash`);
  loadSprouts();
}

async function markDoneGrowing(sproutId) {
  await apiPost(`/sprouts/${sproutId}/done-growing`);
  loadSprouts();
}

function createSproutCard(sprout) {
  const div = document.createElement("div");
  div.className = "card";

  const title = document.createElement("strong");
  title.innerText = sprout.seed_name;
  div.appendChild(title);

  return div;
}

function renderSoakingSprout(div, sprout) {
  const start = new Date(sprout.start_time);
  const now = new Date();

  const elapsedMs = now - start;
  const elapsedHours = elapsedMs / (1000 * 60 * 60);
  const required = sprout.soak_hours || 0;

  if (elapsedHours >= required) {
    addParagraph(div, `Soaking complete (${required}h)`);
  } else {
    addParagraph(div, `Soaking (${elapsedHours.toFixed(1)}h / ${required}h)`);
  }

  const button = document.createElement("button");
  button.innerText = "Done Soaking";
  button.onclick = () => markDoneSoaking(sprout.id);

  div.appendChild(button);
}

function renderGrowingSprout(div, sprout) {
  const currentDay = sprout.current_day;
  const totalDays = sprout.grow_days || 0;

  if (sprout.is_ready_to_harvest) {
    addParagraph(div, `Ready to harvest (Day ${currentDay} / ${totalDays})`);
  } else {
    addParagraph(div, `Growing (Day ${currentDay} / ${totalDays})`);
  }

  addParagraph(
    div,
    `Washes today: ${sprout.washes_done_today} / ${sprout.washes_per_day}`
  );

  const washButton = document.createElement("button");
  washButton.innerText = "Mark Wash Done";
  washButton.onclick = () => markWashDone(sprout.id);

  div.appendChild(washButton);

  const harvestButton = document.createElement("button");
  harvestButton.innerText = "Harvest";
  harvestButton.onclick = () => markDoneGrowing(sprout.id);

  div.appendChild(harvestButton);
}

function renderDoneSprout(div, sprout) {
  addParagraph(div, "Harvested ✔");
}

function renderSprouts(sprouts) {
  const container = document.getElementById("sproutList");
  container.innerHTML = "";

  sprouts.forEach(sprout => {
    const div = createSproutCard(sprout);

    if (sprout.phase === "soaking") {
      renderSoakingSprout(div, sprout);
    } else if (sprout.phase === "growing") {
      renderGrowingSprout(div, sprout);
    } else if (sprout.phase === "done") {
      renderDoneSprout(div, sprout);
    }

    addParagraph(
      div,
      `Soak: ${sprout.soak_hours}h | Grow: ${sprout.grow_days} days | Washes: ${sprout.washes_per_day}/day`
    );

    container.appendChild(div);
  });
}

async function loadSprouts() {
  const sprouts = await apiGet("/sprouts");
  renderSprouts(sprouts);
}


/* =========================
   Calendar
   ========================= */

async function loadCalendar() {
  const data = await apiGet("/calendar");

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

  await apiPost("/settings", { username, theme });

  /* Apply theme immediately */
  document.body.className = theme;

  /* Close modal */
  closeSettings();
}

async function loadSettings() {
  const data = await apiGet("/settings");

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
  loadSprouts();

  updateClock();
  setInterval(updateClock, 1000);

  setInterval(loadHealth, 30000);
  setInterval(loadCalendar, 60000);
  setInterval(loadSprouts, 60000);
}

window.onload = init;