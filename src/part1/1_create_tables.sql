-- CREATE DATABASE postgres;
DROP TABLE IF EXISTS friends CASCADE;
DROP TABLE IF EXISTS p2p CASCADE;
DROP TABLE IF EXISTS recommendations CASCADE;
DROP TABLE IF EXISTS timetracking CASCADE;
DROP TABLE IF EXISTS transferredpoints CASCADE;
DROP TABLE IF EXISTS verter CASCADE;
DROP TABLE IF EXISTS xp CASCADE;
DROP TABLE IF EXISTS checks CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS peers CASCADE;
DROP TYPE IF EXISTS state CASCADE;
CREATE TYPE state AS ENUM ('Start', 'Success', 'Failure');
CREATE TABLE IF NOT EXISTS Peers (
    Nickname varchar(50) primary key not null,
    Birthday date
);
CREATE TABLE IF NOT EXISTS Tasks (
    Title varchar(50) primary key not null,
    ParentTask varchar(50) default null,
    MaxXP int not null,
    foreign key (ParentTask) references Tasks (Title)
);
CREATE TABLE IF NOT EXISTS Checks (
    ID serial primary key,
    Peer varchar(50) not null,
    Task varchar(50) not null,
    Date date,
    foreign key (Peer) references Peers (Nickname),
    foreign key (Task) references Tasks (Title)
);
CREATE TABLE IF NOT EXISTS P2P (
    ID serial primary key,
    Check_ int not null,
    CheckingPeer varchar(50) not null,
    State state,
    Time time,
    foreign key (Check_) references Checks (ID),
    foreign key (CheckingPeer) references Peers (Nickname)
);
CREATE TABLE IF NOT EXISTS Verter (
    ID serial primary key,
    Check_ int not null,
    State state,
    Time time,
    foreign key (Check_) references Checks (ID)
);
CREATE TABLE IF NOT EXISTS XP (
    ID serial primary key,
    Check_ int not null,
    XPAmount int not null,
    foreign key (Check_) references Checks (ID)
);
CREATE TABLE IF NOT EXISTS TransferredPoints (
    ID serial primary key,
    CheckingPeer varchar(50) not null,
    CheckedPeer varchar(50) not null,
    PointsAmount int not null,
    foreign key (CheckingPeer) references Peers (Nickname),
    foreign key (CheckedPeer) references Peers (Nickname),
    check (CheckingPeer != CheckedPeer),
    unique(CheckedPeer, CheckingPeer)
);
CREATE TABLE IF NOT EXISTS Friends (
    ID serial primary key,
    Peer1 varchar(50) not null,
    Peer2 varchar(50) not null,
    foreign key (Peer1) references Peers (Nickname),
    foreign key (Peer2) references Peers (Nickname),
    check (Peer1 != Peer2)
);
CREATE TABLE IF NOT EXISTS Recommendations (
    ID serial primary key,
    Peer varchar(50) not null,
    RecommendedPeer varchar(50),
    foreign key (Peer) references Peers (Nickname),
    foreign key (RecommendedPeer) references Peers (Nickname),
    check (Peer != RecommendedPeer),
    unique (Peer, RecommendedPeer)
);
CREATE TABLE IF NOT EXISTS TimeTracking (
    ID serial primary key,
    Peer varchar(50),
    Date date,
    Time time,
    State int check (State in (1, 2)),
    foreign key (Peer) references Peers (Nickname)
);
--
CREATE OR REPLACE FUNCTION add_friends_foo() RETURNS trigger AS $$
declare x int = (
        select count(*) as count_
        from friends
        where (
                peer1 = new.peer1
                and peer2 = new.peer2
            )
            or (
                peer1 = new.peer2
                and peer2 = new.peer1
            )
    );
BEGIN if x > 1 then
DELETE FROM friends
WHERE ID in(
        SELECT MAX(ID)
        FROM friends
    );
end if;
RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
--
DROP TRIGGER if exists add_friends_trigger on friends;
CREATE TRIGGER add_friends_trigger
AFTER
INSERT ON friends FOR EACH ROW EXECUTE PROCEDURE add_friends_foo();