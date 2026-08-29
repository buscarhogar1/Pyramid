/**
 * Schema used by the temporary multiplayer-room service.
 *
 * A room has no account owner: the unguessable member token returned when a
 * player creates or joins a room is its only credential. Room records expire
 * after 24 hours and are removed on subsequent API requests.
 */
export const roomsTable = {
  code: "TEXT PRIMARY KEY",
  stateJson: "TEXT NOT NULL DEFAULT '{}'",
  version: "INTEGER NOT NULL DEFAULT 0",
  createdAt: "INTEGER NOT NULL",
  expiresAt: "INTEGER NOT NULL",
};

export const roomMembersTable = {
  roomCode: "TEXT NOT NULL",
  memberId: "TEXT NOT NULL",
  tokenHash: "TEXT NOT NULL",
  name: "TEXT NOT NULL",
  isHost: "INTEGER NOT NULL DEFAULT 0",
  joinedAt: "INTEGER NOT NULL",
};

export const roomDrinkEventsTable = {
  id: "TEXT PRIMARY KEY",
  roomCode: "TEXT NOT NULL",
  senderId: "TEXT NOT NULL",
  targetId: "TEXT NOT NULL",
  rank: "TEXT NOT NULL",
  drinks: "INTEGER NOT NULL",
  status: "TEXT NOT NULL DEFAULT 'pending'",
  shownCardJson: "TEXT",
  createdAt: "INTEGER NOT NULL",
  resolvedAt: "INTEGER",
};
