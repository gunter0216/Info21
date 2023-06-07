TRUNCATE TABLE xp CASCADE;
TRUNCATE TABLE p2p CASCADE;
TRUNCATE TABLE checks CASCADE;
TRUNCATE TABLE friends CASCADE;
TRUNCATE TABLE peers CASCADE;
TRUNCATE TABLE recommendations CASCADE;
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE timetracking CASCADE;
TRUNCATE TABLE transferredpoints CASCADE;
TRUNCATE TABLE verter CASCADE;
--
--
INSERT INTO peers (nickname, birthday)
VALUES ('dhammer', '2002-01-26'),
    ('wloyd', '1999-09-09'),
    ('mcarb', '1998-08-08'),
    ('quas', '2010-03-09'),
    ('wex', '2007-11-11'),
    ('exort', '2013-07-09'),
    ('bajaj', '1990-02-25');
INSERT INTO tasks (title, parenttask, maxxp)
VALUES ('s21_SimpleBashUtils', null, 250),
    ('s21_string+', 's21_SimpleBashUtils', 500),
    ('s21_math', 's21_SimpleBashUtils', 300),
    ('s21_decimal', 's21_SimpleBashUtils', 350),
    ('s21_matrix', 's21_decimal', 200),
    ('s21_SmartCalc_v1.0', 's21_matrix', 500),
    ('A_Maze', 's21_matrix', 300),
    ('A_SimpleNavigator', 'A_Maze', 400),
    ('A_Parallels', 'A_SimpleNavigator', 300);
INSERT INTO friends (peer1, peer2)
VALUES ('mcarb', 'wloyd'),
    ('quas', 'dhammer'),
    ('exort', 'quas'),
    ('wex', 'dhammer'),
    ('exort', 'wex');
INSERT INTO recommendations (peer, recommendedpeer)
VALUES ('wex', 'exort'),
    ('dhammer', 'wloyd'),
    ('mcarb', 'wex'),
    ('wex', 'quas'),
    ('quas', 'mcarb');
INSERT INTO timetracking (peer, date, time, state)
VALUES ('wex', '2022-08-24', '15:00', 1),
    ('wex', '2022-08-24', '17:15', 2),
    ('wloyd', '2022-07-12', '12:00', 1),
    ('wloyd', '2022-07-12', '18:25', 2),
    ('quas', '2022-07-07', '07:20', 1),
    ('quas', '2022-07-07', '12:00', 2),
    ('bajaj', '2022-09-04', '08:00', 1),
    ('quas', '2022-09-04', '10:00', 1),
    ('quas', '2022-09-04', '11:25', 2),
    ('exort', '2022-09-04', '09:00', 1),
    ('wex', '2022-09-04', '10:05', 1),
    ('wex', '2022-09-04', '10:45', 2),
    ('wex', '2022-09-04', '11:00', 1),
    ('wex', '2022-08-11', '09:40', 1),
    ('wex', '2022-08-11', '11:00', 2),
    ('wex', '2022-08-12', '10:00', 1),
    ('wex', '2022-08-12', '11:00', 2),
    ('wex', '2022-08-13', '10:20', 1),
    ('wex', '2022-09-13', '11:00', 2);
INSERT INTO transferredpoints (checkingpeer, checkedpeer, pointsamount)
VALUES ('quas', 'wex', 5),
    ('wloyd', 'mcarb', 3),
    ('exort', 'dhammer', 2),
    ('wex', 'quas', 3),
    ('mcarb', 'exort', 4);
INSERT INTO checks (id, peer, task, date)
VALUES (0, 'quas', 's21_SimpleBashUtils', '2022-08-11'),
    (1, 'exort', 's21_SimpleBashUtils', '2022-08-12'),
    (2, 'wex', 's21_SimpleBashUtils', '2022-08-12'),
    (
        3,
        'dhammer',
        's21_SimpleBashUtils',
        '2022-08-12'
    ),
    (4, 'mcarb', 's21_SimpleBashUtils', '2022-08-12'),
    (5, 'bajaj', 's21_SimpleBashUtils', '2022-08-12'),
    (6, 'wloyd', 's21_SimpleBashUtils', '2022-08-12'),
    (7, 'exort', 's21_decimal', '2022-08-20'),
    (8, 'exort', 's21_matrix', '2022-08-29'),
    (9, 'exort', 'A_Maze', '2022-09-05'),
    (10, 'exort', 'A_SimpleNavigator', '2022-09-15'),
    (11, 'exort', 's21_math', '2022-09-18'),
    (12, 'exort', 's21_string+', '2022-09-20'),
    (13, 'exort', 's21_SmartCalc_v1.0', '2022-09-22');
INSERT INTO p2p (check_, checkingpeer, state, time)
VALUES (0, 'exort', 'Start', '9:00'),
    (0, 'exort', 'Success', '9:20'),
    (1, 'mcarb', 'Start', '10:00'),
    (1, 'mcarb', 'Success', '10:15'),
    (2, 'wloyd', 'Start', '13:20'),
    (2, 'wloyd', 'Success', '13:45'),
    (3, 'quas', 'Start', '13:45'),
    (3, 'quas', 'Success', '14:25'),
    (4, 'dhammer', 'Start', '15:00'),
    (4, 'dhammer', 'Success', '15:35'),
    (5, 'wex', 'Start', '15:05'),
    (5, 'wex', 'Failure', '15:20'),
    (6, 'exort', 'Start', '15:08'),
    (6, 'exort', 'Success', '15:25'),
    (7, 'wex', 'Start', '17:00'),
    (7, 'wex', 'Success', '17:25'),
    (8, 'wex', 'Start', '10:00'),
    (8, 'wex', 'Success', '10:20'),
    (9, 'mcarb', 'Start', '15:00'),
    (9, 'mcarb', 'Success', '15:25'),
    (10, 'dhammer', 'Start', '15:00'),
    (10, 'dhammer', 'Success', '15:25'),
    (11, 'wex', 'Start', '10:00'),
    (11, 'wex', 'Success', '10:20'),
    (12, 'mcarb', 'Start', '15:00'),
    (12, 'mcarb', 'Success', '15:25'),
    (13, 'dhammer', 'Start', '15:00'),
    (13, 'dhammer', 'Success', '15:25');
INSERT INTO verter (check_, state, time)
VALUES (0, 'Start', '9:25'),
    (0, 'Success', '9:28'),
    (1, 'Start', '10:00'),
    (1, 'Success', '11:00'),
    (2, 'Start', '13:55'),
    (2, 'Success', '14:02'),
    (3, 'Start', '14:45'),
    (3, 'Success', '14:51'),
    (4, 'Start', '15:45'),
    (4, 'Failure', '15:59'),
    (6, 'Start', '16:00'),
    (6, 'Success', '16:10'),
    (7, 'Start', '17:30'),
    (7, 'Success', '17:41'),
    (8, 'Start', '10:45'),
    (8, 'Failure', '10:51'),
    (11, 'Start', '10:45'),
    (11, 'Failure', '10:51'),
    (12, 'Start', '15:30'),
    (12, 'Success', '15:45'),
    (13, 'Start', '15:38'),
    (13, 'Success', '15:51');
--
--
INSERT INTO xp (check_, xpamount)
SELECT check_,
    (maxxp * (1 -0.5 * random()))::int AS xpamount
FROM(
        SELECT p.check_,
            c.task,
            t.maxxp,
            v.state
        FROM p2p p
            JOIN checks c ON p.check_ = c.id
            JOIN tasks t ON c.task = t.title
            LEFT OUTER JOIN verter v ON v.check_ = p.check_
        where p.state = 'Success'
            AND (
                v.state = 'Success'
                OR v.state IS NULL
            )
    ) AS A;