-- clandb.sqlite3 schema and testing data

PRAGMA foreign_keys=on;

DROP TABLE clans;
DROP TABLE players;
DROP TABLE invites;

CREATE TABLE clans (
  clans_i INTEGER PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE players (
  players_i INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  clans_i INT,
  clan_admin INT NOT NULL DEFAULT 0,
  FOREIGN KEY (clans_i) REFERENCES clans(clans_i)
);

CREATE TABLE invites (
  invitor INT NOT NULL,
  invitee INT NOT NULL,
  creat_when INT DEFAULT current_timestamp,
  FOREIGN KEY (invitor) REFERENCES players(players_i) ON DELETE CASCADE,
  FOREIGN KEY (invitee) REFERENCES players(players_i) ON DELETE CASCADE
);

-- create two clans: "clan1" and "clan2"

INSERT INTO clans VALUES ( 1, 'clan1' );
INSERT INTO clans VALUES ( 2, 'clan2' );

INSERT INTO players (name,clans_i,clan_admin ) VALUES ('Fek',      1, 1);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('discoboy', 1, 0);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('raisse',   1, 0);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('Prowler',  1, 0);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('Wooble',   2, 1);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('rebatela', 2, 0);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('jt',       2, 0);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('kcostell', 2, 0);
INSERT INTO players (name,clans_i,clan_admin ) VALUES ('Tariru', NULL,0);
