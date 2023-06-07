TRUNCATE TABLE p2p CASCADE;
TRUNCATE TABLE checks CASCADE;
TRUNCATE TABLE transferredpoints CASCADE;
TRUNCATE TABLE verter CASCADE;
CALL InsertP2PCheck (
    'quas',
    'exort',
    's21_SimpleBashUtils',
    'Start',
    '09:00:00'
);
CALL InsertP2PCheck (
    'quas',
    'exort',
    's21_SimpleBashUtils',
    'Success',
    '09:20:00'
);
CALL InsertVerterCheck(
    'quas',
    's21_SimpleBashUtils',
    'Start',
    '09:25:00'
);
CALL InsertVerterCheck(
    'quas',
    's21_SimpleBashUtils',
    'Success',
    '09:28:00'
);
--
CALL InsertP2PCheck (
    'exort',
    'mcarb',
    's21_SimpleBashUtils',
    'Start',
    '10:10:00'
);
CALL InsertP2PCheck (
    'exort',
    'mcarb',
    's21_SimpleBashUtils',
    'Success',
    '10:30:00'
);
CALL InsertVerterCheck(
    'exort',
    's21_SimpleBashUtils',
    'Start',
    '10:35:00'
);
CALL InsertVerterCheck(
    'exort',
    's21_SimpleBashUtils',
    'Success',
    '10:50:00'
);
--
CALL InsertP2PCheck (
    'wex',
    'wloyd',
    's21_SimpleBashUtils',
    'Start',
    '01:20:00 PM'
);
CALL InsertP2PCheck (
    'wex',
    'wloyd',
    's21_SimpleBashUtils',
    'Success',
    '01:45:00 PM'
);
CALL InsertVerterCheck(
    'wex',
    's21_SimpleBashUtils',
    'Start',
    '01:50:00 PM'
);
CALL InsertVerterCheck(
    'wex',
    's21_SimpleBashUtils',
    'Failure',
    '01:55:00 PM'
);
--
INSERT INTO xp (check_, xpamount)
VALUES (0, 211);
INSERT INTO xp (check_, xpamount)
VALUES(1, 111);
INSERT INTO xp (check_, xpamount)
VALUES (2, 350);
INSERT INTO xp (check_, xpamount)
VALUES(2, -35);
INSERT INTO xp (check_, xpamount)
VALUES (3, 100);
