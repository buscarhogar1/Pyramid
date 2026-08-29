CREATE TABLE IF NOT EXISTS rooms (
  code TEXT PRIMARY KEY,
  state_json TEXT NOT NULL DEFAULT '{}',
  version INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS room_members (
  room_code TEXT NOT NULL,
  member_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  is_host INTEGER NOT NULL DEFAULT 0,
  joined_at INTEGER NOT NULL,
  PRIMARY KEY (room_code, member_id),
  FOREIGN KEY (room_code) REFERENCES rooms(code) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_rooms_expires_at ON rooms(expires_at);
CREATE INDEX IF NOT EXISTS idx_room_members_room_code ON room_members(room_code);

CREATE TABLE IF NOT EXISTS room_drink_events (
  id TEXT PRIMARY KEY,
  room_code TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  target_id TEXT NOT NULL,
  rank TEXT NOT NULL,
  drinks INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  shown_card_json TEXT,
  created_at INTEGER NOT NULL,
  resolved_at INTEGER,
  FOREIGN KEY (room_code) REFERENCES rooms(code) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_room_drink_events_room_created
  ON room_drink_events(room_code, created_at);
