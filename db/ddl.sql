PRAGMA ENCODING     = "UTF-8";
PRAGMA FOREIGN_KEYS = ON;

/* Список систем АПТ */
CREATE TABLE IF NOT EXISTS APT (
    AptID   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    AptName TEXT    UNIQUE NOT NULL
);
INSERT OR IGNORE INTO  APT (AptID, AptName) VALUES (0, '<нет>');

/* Список депо приписки */
CREATE TABLE IF NOT EXISTS DEPO (
    DepoID   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    DepoName TEXT    UNIQUE NOT NULL
);
INSERT OR IGNORE INTO  DEPO (DepoID, DepoName) VALUES (0, '<нет>');

/* Список серий локомотивов */
CREATE TABLE IF NOT EXISTS LOCOTYPES (
    TypeID    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    LocoType  TEXT    UNIQUE NOT NULL,
    LocoName  TEXT    NOT NULL,
    LocoCount INTEGER NOT NULL DEFAULT 1
);
INSERT OR IGNORE INTO  LOCOTYPES (TypeID, LocoType, LocoName, LocoCount) VALUES (0, '<нет>', '<нет>', 0);

/* Список локомотивов */
CREATE TABLE IF NOT EXISTS LOCO (
    LocoID    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    TypeID    INTEGER NOT NULL DEFAULT 0,
    LocoNum   TEXT    NOT NULL,
    DepoID    INTEGER NOT NULL DEFAULT 0,
    AptID     INTEGER NOT NULL DEFAULT 0,
    IsCurrent INTEGER NOT NULL DEFAULT 1,
    Sec1      INTEGER NOT NULL DEFAULT 1,
    Sec2      INTEGER NOT NULL DEFAULT 0,
    Sec3      INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT FK_LOCO_TYPEID FOREIGN KEY (TypeID) REFERENCES LOCOTYPES(TypeID) ON UPDATE CASCADE ON DELETE SET DEFAULT,
    CONSTRAINT FK_LOCO_DEPOID FOREIGN KEY (DepoID) REFERENCES DEPO(DepoID)      ON UPDATE CASCADE ON DELETE SET DEFAULT,
    CONSTRAINT FK_LOCO_APTID  FOREIGN KEY (AptID)  REFERENCES APT(AptID)        ON UPDATE CASCADE ON DELETE SET DEFAULT
);

/* Список видов технического обслуживания */
CREATE TABLE IF NOT EXISTS TOTYPES (
    TOTypeID   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    TOTypeName TEXT    UNIQUE NOT NULL
);
INSERT OR IGNORE INTO  TOTYPES (TOTypeID, TOTypeName) VALUES (0, '<нет>');

/* Параметры */
CREATE TABLE IF NOT EXISTS SETTINGS (
    SettingName  TEXT PRIMARY KEY NOT NULL,
    SettingValue TEXT NOT NULL
);
INSERT OR IGNORE INTO  SETTINGS (SettingName, SettingValue) VALUES ('Подразделение', ' ');

/* Список замещающих исполнителей */
CREATE TABLE IF NOT EXISTS SUBWORKERS (
    SubManID   INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    SubManName TEXT    UNIQUE NOT NULL
);
INSERT OR IGNORE INTO  SUBWORKERS (SubManID, SubManName) VALUES (0, '<нет>');

/* Список основных исполнителей */
CREATE TABLE IF NOT EXISTS WORKERS (
    ManID    INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    ManName  TEXT    UNIQUE NOT NULL,
    ShiftNum INTEGER NOT NULL DEFAULT 0
);
INSERT OR IGNORE INTO  WORKERS (ManID, ManName, ShiftNum) VALUES (0, '<нет>', 0);

/* Журнал учета обслуживания АПТ */
CREATE TABLE IF NOT EXISTS LOGS (
    LogID    INTEGER  PRIMARY KEY AUTOINCREMENT NOT NULL,
    DayDate  DATETIME NOT NULL,
    LocoID   INTEGER  NOT NULL,
    TOTypeID INTEGER  NOT NULL DEFAULT 0,
    ManID    INTEGER  NOT NULL DEFAULT 0,
    SubManID INTEGER  NOT NULL DEFAULT 0,
    CONSTRAINT FK_LOGS_LOCOID   FOREIGN KEY (LocoID)   REFERENCES LOCO(LocoID)         ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_LOGS_TOTYPEID FOREIGN KEY (TOTypeID) REFERENCES TOTYPES(TOTypeID)    ON UPDATE CASCADE ON DELETE SET DEFAULT,
    CONSTRAINT FK_LOGS_MANID    FOREIGN KEY (ManID)    REFERENCES WORKERS(ManID)       ON UPDATE CASCADE ON DELETE SET DEFAULT,
    CONSTRAINT FK_LOGS_SUBMANID FOREIGN KEY (SubManID) REFERENCES SUBWORKERS(SubManID) ON UPDATE CASCADE ON DELETE SET DEFAULT
);
