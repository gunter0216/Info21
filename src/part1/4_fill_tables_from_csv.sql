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
call import_table('peers.csv', 'peers', ',');
call import_table('tasks.csv', 'tasks', ',');
call import_table('friends.csv', 'friends', ',');
call import_table('recommendations.csv', 'recommendations', ',');
call import_table('timetracking.csv', 'timetracking', ',');
--
--
call import_table('checks.csv', 'checks', ',');
call import_table('p2p.csv', 'p2p', ',');
call import_table('verter.csv', 'verter', ',');
--
INSERT INTO xp (check_, xpamount)
SELECT check_,
    (maxxp * (1 -0.2 * random()))::int AS xpamount
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
call export_xp(',');