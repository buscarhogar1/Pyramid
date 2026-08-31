const ROOM_TTL_MS = 24 * 60 * 60 * 1000;
const MAX_ROOM_MEMBERS = 10;
const MAX_STATE_BYTES = 180000;

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, PUT, OPTIONS",
  "access-control-allow-headers": "content-type, x-room-token",
  "cache-control": "no-store",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, "content-type": "application/json; charset=utf-8" },
  });
}

function fail(error, status = 400) {
  return json({ error }, status);
}

function cleanName(value) {
  return String(value || "").trim().replace(/\s+/g, " ").slice(0, 20);
}

function cleanCode(value) {
  return String(value || "").toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 6);
}

function randomString(length) {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (byte) => alphabet[byte % alphabet.length]).join("");
}

function randomToken() {
  const bytes = new Uint8Array(24);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function hashToken(token) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function getToken(request) {
  const value = request.headers.get("x-room-token") || "";
  return /^[a-f0-9]{48}$/i.test(value) ? value : "";
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return null;
  }
}

function parseState(raw) {
  try {
    const state = JSON.parse(raw || "{}");
    return state && typeof state === "object" && !Array.isArray(state) ? state : {};
  } catch {
    return {};
  }
}

async function ensureSchema(db) {
  await db.batch([
    db.prepare("CREATE TABLE IF NOT EXISTS rooms (code TEXT PRIMARY KEY, state_json TEXT NOT NULL DEFAULT '{}', version INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, expires_at INTEGER NOT NULL)"),
    db.prepare("CREATE TABLE IF NOT EXISTS room_members (room_code TEXT NOT NULL, member_id TEXT NOT NULL, token_hash TEXT NOT NULL, name TEXT NOT NULL, is_host INTEGER NOT NULL DEFAULT 0, joined_at INTEGER NOT NULL, PRIMARY KEY (room_code, member_id), FOREIGN KEY (room_code) REFERENCES rooms(code) ON DELETE CASCADE)"),
    db.prepare("CREATE TABLE IF NOT EXISTS room_drink_events (id TEXT PRIMARY KEY, room_code TEXT NOT NULL, sender_id TEXT NOT NULL, target_id TEXT NOT NULL, rank TEXT NOT NULL, drinks INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending', shown_card_json TEXT, created_at INTEGER NOT NULL, resolved_at INTEGER, FOREIGN KEY (room_code) REFERENCES rooms(code) ON DELETE CASCADE)"),
    db.prepare("CREATE INDEX IF NOT EXISTS idx_rooms_expires_at ON rooms(expires_at)"),
    db.prepare("CREATE INDEX IF NOT EXISTS idx_room_members_room_code ON room_members(room_code)"),
    db.prepare("CREATE INDEX IF NOT EXISTS idx_room_drink_events_room_created ON room_drink_events(room_code, created_at)"),
  ]);
}

async function removeExpired(db) {
  const now = Date.now();
  await db.batch([
    db.prepare("DELETE FROM room_drink_events WHERE room_code IN (SELECT code FROM rooms WHERE expires_at <= ?)").bind(now),
    db.prepare("DELETE FROM room_members WHERE room_code IN (SELECT code FROM rooms WHERE expires_at <= ?)").bind(now),
    db.prepare("DELETE FROM rooms WHERE expires_at <= ?").bind(now),
  ]);
}

async function getRoom(db, code) {
  return db.prepare("SELECT code, state_json, version, expires_at FROM rooms WHERE code = ?").bind(code).first();
}

async function membersForRoom(db, code) {
  const result = await db.prepare("SELECT member_id, name, is_host FROM room_members WHERE room_code = ? ORDER BY joined_at ASC").bind(code).all();
  return (result.results || []).map((member) => ({ id: member.member_id, name: member.name, host: Boolean(member.is_host) }));
}

async function authorize(db, code, memberId, token) {
  if (!memberId || !token) return null;
  return db.prepare("SELECT member_id, name, is_host FROM room_members WHERE room_code = ? AND member_id = ? AND token_hash = ?").bind(code, memberId, await hashToken(token)).first();
}

function parseCard(raw) {
  const card = parseState(raw);
  return card.rank ? card : null;
}

async function drinkEventsForRoom(db, code) {
  const result = await db.prepare("SELECT id, sender_id, target_id, rank, drinks, status, shown_card_json, created_at, resolved_at FROM room_drink_events WHERE room_code = ? ORDER BY created_at DESC LIMIT 40").bind(code).all();
  return (result.results || []).reverse().map((event) => ({
    id: event.id,
    senderId: event.sender_id,
    targetId: event.target_id,
    rank: event.rank,
    drinks: Number(event.drinks),
    status: event.status,
    shownCard: parseCard(event.shown_card_json),
    createdAt: Number(event.created_at),
    resolvedAt: event.resolved_at == null ? null : Number(event.resolved_at),
  }));
}

async function roomPayload(db, room) {
  return { code: room.code, version: Number(room.version), state: parseState(room.state_json), members: await membersForRoom(db, room.code), drinkEvents: await drinkEventsForRoom(db, room.code) };
}

async function createRoom(db, request) {
  const name = cleanName((await readJson(request))?.name);
  if (!name) return fail("invalid_name");
  const now = Date.now();
  let code = "";
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const candidate = randomString(6);
    if (!await getRoom(db, candidate)) { code = candidate; break; }
  }
  if (!code) return fail("room_creation_failed", 503);

  const memberId = randomToken().slice(0, 16);
  const token = randomToken();
  await db.batch([
    db.prepare("INSERT INTO rooms (code, state_json, version, created_at, expires_at) VALUES (?, ?, 0, ?, ?)").bind(code, '{"screen":"roomlobby"}', now, now + ROOM_TTL_MS),
    db.prepare("INSERT INTO room_members (room_code, member_id, token_hash, name, is_host, joined_at) VALUES (?, ?, ?, ?, 1, ?)").bind(code, memberId, await hashToken(token), name, now),
  ]);
  const room = await getRoom(db, code);
  return json({ ...await roomPayload(db, room), token, member: { id: memberId, name, host: true } }, 201);
}

async function joinRoom(db, request, code) {
  const name = cleanName((await readJson(request))?.name);
  if (!name) return fail("invalid_name");
  const room = await getRoom(db, code);
  if (!room) return fail("room_not_found", 404);
  if (parseState(room.state_json).screen !== "roomlobby") return fail("room_already_started", 409);
  if ((await membersForRoom(db, code)).length >= MAX_ROOM_MEMBERS) return fail("room_full", 409);

  const memberId = randomToken().slice(0, 16);
  const token = randomToken();
  await db.prepare("INSERT INTO room_members (room_code, member_id, token_hash, name, is_host, joined_at) VALUES (?, ?, ?, ?, 0, ?)").bind(code, memberId, await hashToken(token), name, Date.now()).run();
  return json({ ...await roomPayload(db, room), token, member: { id: memberId, name, host: false } }, 201);
}

async function readRoom(db, request, url, code) {
  const room = await getRoom(db, code);
  if (!room) return fail("room_not_found", 404);
  if (!await authorize(db, code, url.searchParams.get("member") || "", getToken(request))) return fail("room_access_denied", 401);
  return json(await roomPayload(db, room));
}

async function updateRoomState(db, request, code) {
  const body = await readJson(request);
  if (!await authorize(db, code, String(body?.member || ""), getToken(request))) return fail("room_access_denied", 401);
  if (!await getRoom(db, code)) return fail("room_not_found", 404);
  if (!body?.state || typeof body.state !== "object" || Array.isArray(body.state)) return fail("invalid_room_state");
  const serialized = JSON.stringify(body.state);
  if (serialized.length > MAX_STATE_BYTES) return fail("room_state_too_large", 413);
  if (!Number.isInteger(Number(body.version))) return fail("invalid_room_version");
  const result = await db.prepare("UPDATE rooms SET state_json = ?, version = version + 1 WHERE code = ? AND version = ?").bind(serialized, code, Number(body.version)).run();
  if (!result.meta?.changes) return fail("room_state_conflict", 409);
  const room = await getRoom(db, code);
  return json({ code, version: Number(room.version) });
}

async function createDrinkEvent(db, request, code) {
  const body = await readJson(request);
  const member = await authorize(db, code, String(body?.member || ""), getToken(request));
  if (!member) return fail("room_access_denied", 401);
  const room = await getRoom(db, code);
  if (!room) return fail("room_not_found", 404);
  const state = parseState(room.state_json);
  const card = state.flippedCard;
  if (state.screen !== "play" || state.phase === "flip" || !card?.rank || !Number.isFinite(Number(card.drinks))) return fail("drink_event_not_available", 409);
  const targetId = String(body?.target || "");
  const members = await membersForRoom(db, code);
  if (!targetId || targetId === member.member_id || !members.some((item) => item.id === targetId)) return fail("invalid_drink_target");
  const event = { id: randomToken().slice(0, 20), senderId: member.member_id, targetId, rank: String(card.rank).slice(0, 8), drinks: Math.max(1, Math.floor(Number(card.drinks))), status: "pending", createdAt: Date.now() };
  await db.prepare("INSERT INTO room_drink_events (id, room_code, sender_id, target_id, rank, drinks, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)").bind(event.id, code, event.senderId, event.targetId, event.rank, event.drinks, event.status, event.createdAt).run();
  return json({ event }, 201);
}

async function respondToDrinkEvent(db, request, code, eventId) {
  const body = await readJson(request);
  const member = await authorize(db, code, String(body?.member || ""), getToken(request));
  if (!member) return fail("room_access_denied", 401);
  const decision = String(body?.decision || "");
  if (decision !== "accept" && decision !== "challenge") return fail("invalid_drink_response");
  const event = await db.prepare("SELECT id, sender_id, target_id, rank, drinks, status FROM room_drink_events WHERE id = ? AND room_code = ?").bind(eventId, code).first();
  if (!event) return fail("drink_event_not_found", 404);
  if (event.target_id !== member.member_id) return fail("drink_event_forbidden", 403);
  if (event.status !== "pending") return fail("drink_event_already_resolved", 409);
  let status = "accepted";
  let shownCard = null;
  if (decision === "challenge") {
    const room = await getRoom(db, code);
    const members = await membersForRoom(db, code);
    const senderIndex = members.findIndex((item) => item.id === event.sender_id);
    const cards = Array.isArray(parseState(room?.state_json).hands?.[senderIndex]) ? parseState(room.state_json).hands[senderIndex] : [];
    shownCard = cards.find((card) => String(card?.rank || "") === String(event.rank)) || cards[0] || null;
    status = shownCard?.rank === event.rank ? "truth" : "lie";
  }
  const resolvedAt = Date.now();
  const result = await db.prepare("UPDATE room_drink_events SET status = ?, shown_card_json = ?, resolved_at = ? WHERE id = ? AND room_code = ? AND status = 'pending'").bind(status, shownCard ? JSON.stringify(shownCard) : null, resolvedAt, eventId, code).run();
  if (!result.meta?.changes) return fail("drink_event_already_resolved", 409);
  return json({ event: { id: event.id, senderId: event.sender_id, targetId: event.target_id, rank: event.rank, drinks: Number(event.drinks), status, shownCard, resolvedAt } });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS_HEADERS });
    if (url.pathname === "/") return new Response("Pyramid Rooms API", { headers: { ...CORS_HEADERS, "content-type": "text/plain; charset=utf-8" } });
    if (!url.pathname.startsWith("/api/rooms")) return new Response("Not found", { status: 404 });
    if (!env.DB) return fail("room_service_unavailable", 503);
    try {
      await ensureSchema(env.DB);
      await removeExpired(env.DB);
      const parts = url.pathname.split("/").filter(Boolean);
      if (parts.length === 2 && request.method === "POST") return createRoom(env.DB, request);
      const code = cleanCode(parts[2]);
      if (code.length !== 6) return fail("invalid_room_code");
      if (parts.length === 3 && request.method === "GET") return readRoom(env.DB, request, url, code);
      if (parts.length === 4 && parts[3] === "join" && request.method === "POST") return joinRoom(env.DB, request, code);
      if (parts.length === 4 && parts[3] === "state" && request.method === "PUT") return updateRoomState(env.DB, request, code);
      if (parts.length === 4 && parts[3] === "events" && request.method === "POST") return createDrinkEvent(env.DB, request, code);
      if (parts.length === 6 && parts[3] === "events" && parts[5] === "respond" && request.method === "POST") return respondToDrinkEvent(env.DB, request, code, String(parts[4] || ""));
      return fail("not_found", 404);
    } catch (error) {
      console.error("room API error", error);
      return fail("room_service_unavailable", 503);
    }
  },
};
