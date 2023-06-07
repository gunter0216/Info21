-- 1) Write a procedure for adding P2P check
-- Parameters: nickname of the person being checked, checker's nickname, task name, P2P check status, time. 
-- If the status is "start", add a record in the Checks table (use today's date). 
-- Add a record in the P2P table. 
-- If the status is "start", specify the record just added as a check, 
-- otherwise specify the check with the latest (by time) unfinished P2P step.
DROP PROCEDURE IF EXISTS InsertP2PCheck;
CREATE OR REPLACE PROCEDURE InsertP2PCheck (
        _CheckedPeer peers.nickname % TYPE,
        _CheckingPeer peers.nickname % TYPE,
        _task tasks.title % TYPE,
        _state state,
        _time time
    ) LANGUAGE plpgsql AS $$
DECLARE _check_id int;
BEGIN IF _state = 'Start' THEN
INSERT INTO Checks (Peer, Task, Date)
VALUES (
        _CheckedPeer,
        _task,
        (
            SELECT CURRENT_DATE
        )
    );
_check_id = (
    SELECT last_value
    FROM checks_id_seq
);
ELSE _check_id = (
    WITH s AS (
        SELECT *
        FROM p2p
        WHERE (state = 'Start')
    ),
    e AS (
        SELECT *
        FROM p2p
        WHERE (state != 'Start')
    ),
    f AS (
        SELECT s.check_,
            s.checkingpeer,
            s.state AS begin_state,
            s.time AS start_time,
            e.state AS end_state,
            e.time AS end_time
        FROM s
            FULL JOIN e USING (check_, checkingpeer)
        WHERE e.state IS NULL
        ORDER BY s.check_ DESC
    )
    SELECT check_
    FROM f
    WHERE (checkingpeer = _CheckingPeer)
    ORDER BY check_ DESC,
        start_time DESC
    LIMIT 1
);
END IF;
INSERT INTO P2P (check_, checkingpeer, state, time)
VALUES (
        _check_id,
        _CheckingPeer,
        _state,
        _time
    );
END;
$$;
--
-- 2) Write a procedure for adding checking by Verter
-- Parameters: nickname of the person being checked, task name, Verter check status, time. 
-- Add a record to the Verter table (as a check specify the check of the corresponding task 
-- with the latest (by time) successful P2P step)
DROP PROCEDURE IF EXISTS InsertVerterCheck;
CREATE OR REPLACE PROCEDURE InsertVerterCheck(
        _CheckedPeer peers.nickname % TYPE,
        _task tasks.title % TYPE,
        _state state,
        _time time
    ) LANGUAGE plpgsql AS $$
DECLARE _check_id int;
BEGIN _check_id = (
    SELECT checks.id
    FROM p2p
        JOIN checks ON p2p.check_ = checks.id
    WHERE state = 'Success'
        AND checks.task = _task
    ORDER BY time DESC,
        checks.id DESC
    LIMIT 1
);
INSERT INTO verter (check_, state, time)
VALUES (
        _check_id,
        _state,
        _time
    );
END;
$$;
--
-- 3) Write a trigger: after adding a record with the "start" status to the P2P table, 
-- change the corresponding record in the TransferredPoints table
DROP TRIGGER IF EXISTS trg_P2P ON p2p;
DROP FUNCTION IF EXISTS fnc_trg_P2P;
CREATE OR REPLACE FUNCTION fnc_trg_P2P() RETURNS trigger AS $$
DECLARE _checkedpeer peers.nickname % TYPE;
current_points int;
BEGIN if (NEW.state = 'Start') THEN _checkedpeer = (
    SELECT peer
    FROM checks
    WHERE id = NEW.check_
);
current_points =(
    SELECT pointsamount
    FROM transferredpoints
    WHERE checkingpeer = NEW.checkingpeer
        AND checkedpeer = _checkedpeer
);
IF current_points IS NULL THEN
INSERT INTO TransferredPoints(checkingpeer, checkedpeer, pointsamount)
VALUES(
        NEW.checkingpeer,
        _checkedpeer,
        1
    );
ELSE
UPDATE TransferredPoints
SET pointsamount = current_points + 1
WHERE checkingpeer = NEW.checkingpeer
    AND checkedpeer = _checkedpeer;
END IF;
end if;
RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
--
CREATE OR REPLACE TRIGGER trg_P2P
AFTER
INSERT ON P2P FOR EACH ROW EXECUTE PROCEDURE fnc_trg_P2P();
--
-- 4) Write a trigger: before adding a record to the XP table, check if it is correct
-- The record is considered correct if:
-- The number of XP does not exceed the maximum available for the task being checked
-- The Check field refers to a successful check
-- If the record does not pass the check, do not add it to the table.
DROP TRIGGER IF EXISTS trg_XP ON xp;
DROP FUNCTION IF EXISTS fnc_trg_XP;
--
CREATE OR REPLACE FUNCTION fnc_trg_XP() RETURNS trigger AS $$
DECLARE maxXpAmount xp.xpamount % TYPE;
checkTitle tasks.title % TYPE;
checkStatus boolean;
BEGIN checkTitle = (
    SELECT task
    FROM checks
    WHERE checks.id = NEW.check_
);
maxXpAmount = (
    SELECT maxxp
    FROM tasks
    WHERE title = checkTitle
);
IF (
    EXISTS (
        SELECT state
        FROM p2p
        WHERE check_ = NEW.check_
            AND state = 'Success'
    )
    AND (
        EXISTS(
            SELECT state
            FROM verter
            WHERE check_ = NEW.check_
                AND state = 'Success'
        )
        OR NOT EXISTS(
            SELECT state
            FROM verter
            WHERE check_ = NEW.check_
        )
    )
) THEN checkStatus = 'true';
ELSE checkStatus = 'false';
END IF;
IF NEW.xpamount > maxXpAmount THEN RETURN NULL;
ELSIF checkStatus = 'false' THEN RETURN NULL;
END IF;
RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
--
CREATE OR REPLACE TRIGGER trg_XP BEFORE
INSERT ON xp FOR EACH ROW EXECUTE PROCEDURE fnc_trg_XP();
--