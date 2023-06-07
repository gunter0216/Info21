-- 1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов. 
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
DROP FUNCTION IF EXISTS TransferredPoints;
CREATE OR REPLACE FUNCTION TransferredPoints () RETURNS TABLE (peer1 varchar, peer2 varchar, PointsAmount int) AS $$ BEGIN RETURN QUERY EXECUTE 'SELECT 
        Peer1, 
        Peer2, 
        COALESCE(t1.PointsAmount, 0) - COALESCE(t2.PointsAmount, 0) AS PointsAmount
    FROM
    (SELECT DISTINCT
        CASE WHEN CheckingPeer > CheckedPeer THEN CheckingPeer ELSE CheckedPeer END AS Peer1,
        CASE WHEN CheckingPeer <= CheckedPeer THEN CheckingPeer ELSE CheckedPeer END AS Peer2
     FROM TransferredPoints)p 
    LEFT JOIN TransferredPoints t1 ON p.Peer1 = t1.CheckingPeer AND p.Peer2 = t1.CheckedPeer
    LEFT JOIN TransferredPoints t2 ON p.Peer1 = t2.CheckedPeer AND p.Peer2 = t2.CheckingPeer
    ORDER BY Peer1, Peer2 ';
END;
$$ LANGUAGE plpgsql;
--
--
-- 2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, 
-- кол-во полученного XP
-- В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks).
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.
DROP FUNCTION IF EXISTS CheckedPeersWithXP;
CREATE OR REPLACE FUNCTION CheckedPeersWithXP() RETURNS TABLE(
        Peer varchar(255),
        Task varchar(255),
        XP int
    ) AS $$
select c.peer,
    c.task,
    xp.xpamount
from p2p p
    left join checks c on p.check_ = c.id
    left join verter v on v.check_ = c.id
    left join xp on c.id = xp.check_
    left join tasks t on t.title = c.task
where p.state = 'Success'
    AND (
        v.state = 'Success'
        OR v.state IS NULL
    )
    AND xp.xpamount * 100 / t.maxxp >= 80;
$$ LANGUAGE SQL;
--
-- 3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например 12.05.2022.
-- Функция возвращает только список пиров.
DROP FUNCTION IF EXISTS PeersInCampus;
CREATE OR REPLACE FUNCTION PeersInCampus(date_ date) RETURNS TABLE(Peer varchar(30)) AS $$ WITH count_ AS (
        SELECT t1.peer,
            t1.date,
            t1.state,
            COUNT(t1.peer) AS cv
        FROM timetracking t1
        GROUP BY t1.date,
            t1.peer,
            t1.state
    )
SELECT DISTINCT t3.peer
FROM (
        SELECT t.peer,
            t.date
        FROM timetracking t
        WHERE (
                SELECT cv
                FROM count_ c
                WHERE t.peer = c.peer
                    AND t.date = c.date
                    AND c.state = 1
            ) = 1
            AND (
                (
                    SELECT cv
                    FROM count_ c
                    WHERE t.peer = c.peer
                        AND t.date = c.date
                        AND c.state = 2
                ) = 1
                OR NOT EXISTS (
                    SELECT cv
                    FROM count_ c
                    WHERE t.peer = c.peer
                        AND t.date = c.date
                        AND c.state = 2
                )
            )
    ) as t3
WHERE date = date_;
$$ LANGUAGE SQL;
--
-- 4) Найти процент успешных и неуспешных проверок за всё время
-- Формат вывода: процент успешных, процент неуспешных
DROP PROCEDURE IF EXISTS CheckSuccessRatio;
CREATE OR REPLACE PROCEDURE CheckSuccessRatio(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR WITH all_count as (
        SELECT count(*) / 2 as count_
        FROM p2p
    ),
    success_count as (
        SELECT count(*) as count_
        FROM p2p
        WHERE state = 'Success'
    )
SELECT success_count.count_ * 100 / all_count.count_ as SuccessfulChecks,
    (all_count.count_ - success_count.count_) * 100 / all_count.count_ as UnsuccessfulChecks
FROM all_count,
    success_count;
END;
$$;
--
-- 5) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов
CREATE OR REPLACE PROCEDURE PointsChange(result_data refcursor) AS $$ BEGIN OPEN result_data FOR
SELECT Peer,
    SUM(PointsChange) AS PointsChange
FROM (
        SELECT CheckingPeer AS Peer,
            PointsAmount AS PointsChange
        FROM TransferredPoints
        UNION
        SELECT CheckedPeer,
            - PointsAmount
        FROM TransferredPoints
    ) chages
GROUP BY Peer
ORDER BY PointsChange;
END;
$$ LANGUAGE plpgsql;
--
-- 6) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3
-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов
CREATE OR REPLACE PROCEDURE PointsChange_v2(result_data refcursor) AS $$ BEGIN OPEN result_data FOR
SELECT Peer,
    SUM(pointsamount) AS PointsChange
FROM (
        SELECT peer1 AS peer,
            pointsamount
        FROM transferredpoints()
        UNION
        SELECT peer2,
            - pointsamount
        FROM transferredpoints()
    ) tp
GROUP BY Peer
ORDER BY PointsChange;
END;
$$ LANGUAGE plpgsql;
-- 
-- 7) Определить самое часто проверяемое задание за каждый день
-- При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все. 
-- Формат вывода: день, название задания
DROP PROCEDURE IF EXISTS MostFrequentTaskDaily;
CREATE OR REPLACE PROCEDURE MostFrequentTaskDaily (result_data refcursor) LANGUAGE plpgsql AS $$
DECLARE _check_id int;
BEGIN OPEN result_data FOR WITH A AS (
    SELECT date,
        checks.task,
        COUNT(id) AS countId
    FROM checks
    GROUP BY checks.task,
        date
)
SELECT date AS day,
    B.task
FROM (
        SELECT A.task,
            A.date,
            rank() OVER (
                PARTITION BY A.date
                ORDER BY countId DESC
            ) AS rank
        FROM A
    ) AS B
WHERE rank = 1
ORDER BY day;
END;
$$;
--
-- 8) Определить длительность последней P2P проверки
-- Под длительностью подразумевается разница между временем, 
-- указанным в записи со статусом "начало", и временем, указанным в записи со статусом "успех" или "неуспех". 
-- Формат вывода: длительность проверки
DROP PROCEDURE IF EXISTS DurationLatestP2PCheck;
CREATE OR REPLACE PROCEDURE DurationLatestP2PCheck () LANGUAGE plpgsql AS $$
DECLARE _check_id int;
time_start time;
time_end time;
duration interval;
BEGIN _check_id = (
    WITH A AS (
        SELECT date + time AS datetime,
            peer,
            checkingpeer,
            state,
            check_
        FROM p2p
            LEFT JOIN checks ON p2p.check_ = checks.id
    )
    SELECT check_
    FROM A
    WHERE datetime = (
            SELECT max(datetime)
            FROM A
        )
    ORDER BY check_
    LIMIT 1
);
time_start =(
    SELECT time
    FROM p2p
    WHERE check_ = _check_id
        AND state = 'Start'
);
time_end =(
    SELECT time
    FROM p2p
    WHERE check_ = _check_id
        AND state != 'Start'
);
SET intervalstyle = postgres_verbose;
duration = time_end - time_start;
RAISE NOTICE '%',
duration;
END;
$$;
--
--
-- 9) Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
-- Параметры процедуры: название блока, например "CPP". 
-- Результат вывести отсортированным по дате завершения. 
-- Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)
DROP PROCEDURE IF EXISTS CompleteBlock;
CREATE OR REPLACE PROCEDURE CompleteBlock(result_data refcursor, block varchar) LANGUAGE plpgsql AS $$
DECLARE count integer;
BEGIN count = (
    SELECT COUNT(tasks.title)
    FROM tasks
    WHERE tasks.title ~ CONCAT('^', block)
);
OPEN result_data FOR WITH A AS (
    SELECT p2p.check_,
        p2p.state
    FROM p2p
    WHERE p2p.state = 'Success'
),
B AS (
    SELECT verter.check_,
        verter.state
    FROM verter
    WHERE verter.state = 'Success'
),
C AS (
    SELECT COUNT(id) AS count_success,
        MAX(date) AS day,
        peer
    FROM checks
    WHERE task ~ CONCAT('^', block)
        AND checks.id IN (
            SELECT check_
            FROM A
        )
        AND checks.id IN (
            SELECT check_
            FROM A
        )
    GROUP BY peer
)
SELECT peer,
    day
FROM C
WHERE count_success = count;
END;
$$;
--
-- 10) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
-- Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. 
-- Формат вывода: ник пира, ник найденного проверяющего
CREATE OR REPLACE PROCEDURE FindPeerForCheck(result_data refcursor) AS $$ BEGIN OPEN result_data FOR WITH recomend_count AS (
        SELECT f.peer,
            COUNT(friend) AS recommendations_count,
            RecommendedPeer
        FROM (
                SELECT Peer1 AS peer,
                    Peer2 AS friend
                FROM friends
                UNION
                SELECT Peer2,
                    Peer1
                FROM friends
            ) f
            JOIN recommendations ON f.friend = recommendations.peer
            AND f.peer <> recommendations.recommendedpeer
        GROUP BY f.peer,
            recommendedpeer
    )
SELECT r.peer as Peer,
    recomend_count.RecommendedPeer
FROM (
        SELECT peer,
            MAX(recommendations_count) AS max_recomend_count
        FROM recomend_count
        GROUP BY peer
    ) r
    JOIN recomend_count ON r.peer = recomend_count.peer
    AND r.max_recomend_count = recomend_count.recommendations_count
ORDER BY Peer,
    RecommendedPeer;
END;
$$ LANGUAGE plpgsql;
--
-- 11) Определить процент пиров, которые:
--
-- Приступили к блоку 1
-- Приступили к блоку 2
-- Приступили к обоим
-- Не приступили ни к одному
--
-- Параметры процедуры: название блока 1, например CPP, название блока 2, например A.
-- Формат вывода: процент приступивших к первому блоку, процент приступивших ко второму блоку, 
-- процент приступивших к обоим, процент не приступивших ни к одному
DROP PROCEDURE IF EXISTS PeersByGroups;
CREATE OR REPLACE PROCEDURE PeersByGroups(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR with count_peers as (
        select count(*) as count_
        from peers
    ),
    count_peers_C as (
        select count(*) as count_
        from (
                select distinct on (peer) *
                from checks
                where task ~ '^s21'
            ) as temp
    ),
    count_peers_CPP as (
        select count(*) as count_
        from (
                select distinct on (peer) *
                from checks
                where task ~ '^A'
            ) as temp
    ),
    count_peers_none as (
        select count(*) as count_
        from peers
            left join (
                select *
                from checks
                where task ~ '^(A|s21)'
            ) as temp on peers.nickname = temp.peer
        where id is null
    ),
    count_peers_all as (
        select count(*) as count_
        from (
                select distinct on (peer) peer
                from checks
                where task ~ '^s21'
                intersect
                select distinct on (peer) peer
                from checks
                where task ~ '^A'
            ) as temp
    )
select (count_peers_C.count_ * 100 / count_peers.count_) as StartedBlock1,
    (
        count_peers_CPP.count_ * 100 / count_peers.count_
    ) as StartedBlock2,
    (
        count_peers_all.count_ * 100 / count_peers.count_
    ) as StartedBothBlocks,
    (
        count_peers_none.count_ * 100 / count_peers.count_
    ) as DidntStartAnyBlock
from count_peers_none,
    count_peers_C,
    count_peers,
    count_peers_all,
    count_peers_CPP;
END;
$$;
--
-- 12) Определить N пиров с наибольшим числом друзей
-- Параметры процедуры: количество пиров N. 
-- Результат вывести отсортированным по кол-ву друзей. 
-- Формат вывода: ник пира, количество друзей
DROP PROCEDURE IF EXISTS PeersWithGreatestNumberFriends;
CREATE OR REPLACE PROCEDURE PeersWithGreatestNumberFriends(result_data refcursor, N int) AS $$ BEGIN OPEN result_data FOR
SELECT Peer,
    COUNT(friend) AS FriendsCount
FROM (
        SELECT Peer1 AS peer,
            Peer2 AS friend
        FROM friends
        UNION
        SELECT Peer2,
            Peer1
        FROM friends
    ) f
GROUP BY Peer
ORDER BY FriendsCount DESC
LIMIT N;
END;
$$ LANGUAGE plpgsql;
--
-- 13) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
-- Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения.
-- Формат вывода: процент успехов в день рождения, процент неуспехов в день рождения
DROP FUNCTION IF EXISTS FPeersWithBDayCheck;
CREATE OR REPLACE FUNCTION FPeersWithBDayCheck() RETURNS TABLE(
        SuccessfulChecks int,
        UnsuccessfulChecks int
    ) AS $$ with temp_table as (
        select state
        from p2p
            left join checks on p2p.check_ = checks.id
            left join peers on checks.peer = peers.nickname
        where extract(
                day
                from checks.date
            ) = extract(
                day
                from peers.birthday
            )
            and extract(
                month
                from checks.date
            ) = extract(
                month
                from peers.birthday
            )
    ),
    all_count as (
        select count(*) as count_
        from temp_table
        where state = 'Start'
    ),
    success_count as (
        select count(*) as count_
        from temp_table
        where state = 'Success'
    ),
    failure_count as (
        select count(*) as count_
        from temp_table
        where state = 'Failure'
    )
select (success_count.count_ * 100 / all_count.count_),
    (failure_count.count_ * 100 / all_count.count_)
from success_count,
    failure_count,
    all_count;
$$ LANGUAGE SQL;
--
DROP PROCEDURE IF EXISTS PeersWithBDayCheck;
CREATE OR REPLACE PROCEDURE PeersWithBDayCheck(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR with temp_table as (
        select state
        from p2p
            left join checks on p2p.check_ = checks.id
            left join peers on checks.peer = peers.nickname
        where extract(
                day
                from checks.date
            ) = extract(
                day
                from peers.birthday
            )
            and extract(
                month
                from checks.date
            ) = extract(
                month
                from peers.birthday
            )
    ),
    all_count as (
        select count(*) as count_
        from temp_table
        where state = 'Start'
    ),
    success_count as (
        select count(*) as count_
        from temp_table
        where state = 'Success'
    ),
    failure_count as (
        select count(*) as count_
        from temp_table
        where state = 'Failure'
    )
select (
        success_count.count_ * 100 / CASE
            WHEN all_count.count_ = 0 THEN 1
            ELSE all_count.count_
        END
    ) AS SuccessfulChecks,
    (
        failure_count.count_ * 100 / CASE
            WHEN all_count.count_ = 0 THEN 1
            ELSE all_count.count_
        END
    ) AS UnsuccessfulChecks
from success_count,
    failure_count,
    all_count;
END;
$$;
--
-- 14) Определить кол-во XP, полученное в сумме каждым пиром
-- Если одна задача выполнена несколько раз, полученное за нее кол-во XP равно максимальному за эту задачу. 
-- Результат вывести отсортированным по кол-ву XP. 
-- Формат вывода: ник пира, количество XP
DROP PROCEDURE IF EXISTS TotalXP;
CREATE OR REPLACE PROCEDURE TotalXP(result_data refcursor) AS $$ BEGIN OPEN result_data FOR
SELECT peer AS Peer,
    SUM(XPAmount) AS XP
FROM (
        SELECT peer,
            task,
            MAX(XPAmount) AS XPAmount
        FROM xp
            JOIN checks ON xp.check_ = checks.id
        GROUP BY peer,
            task
    ) xp
GROUP BY peer
ORDER BY XP;
END;
$$ LANGUAGE plpgsql;
--
-- 15) Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
-- Параметры процедуры: названия заданий 1, 2 и 3. 
-- Формат вывода: список пиров
DROP PROCEDURE IF EXISTS GivenAndNotGivenTasks;
CREATE OR REPLACE PROCEDURE GivenAndNotGivenTasks(
        result_data refcursor,
        task1 varchar,
        task2 varchar,
        task3 varchar
    ) AS $$ BEGIN OPEN result_data FOR
SELECT Peer
FROM (
        SELECT Peer,
            SUM(
                CASE
                    WHEN Task = task1 THEN 1
                    ELSE 0
                END
            ) AS is_task1_do,
            SUM(
                CASE
                    WHEN Task = task2 THEN 1
                    ELSE 0
                END
            ) AS is_task2_do,
            SUM(
                CASE
                    WHEN Task = task3 THEN 1
                    ELSE 0
                END
            ) AS is_task3_do
        FROM (
                SELECT DISTINCT Peer,
                    Task
                FROM xp
                    JOIN checks ON xp.check_ = checks.id
            ) ch
        GROUP BY Peer
    ) is_do
WHERE is_task1_do = 1
    and is_task2_do = 1
    and is_task3_do = 0;
END;
$$ LANGUAGE plpgsql;
--
-- 16) Используя рекурсивное обобщенное табличное выражение, 
-- для каждой задачи вывести кол-во предшествующих ей задач
-- То есть сколько задач нужно выполнить, исходя из условий входа, 
-- чтобы получить доступ к текущей. 
-- Формат вывода: название задачи, количество предшествующих
DROP PROCEDURE IF EXISTS CountOfPreviousTasks;
CREATE OR REPLACE PROCEDURE CountOfPreviousTasks(result_data refcursor) LANGUAGE plpgsql AS $$
DECLARE count_tasks integer;
BEGIN OPEN result_data FOR WITH RECURSIVE recursiveQuery(title, parenttask, n) AS (
    SELECT tasks.title,
        tasks.parenttask,
        0
    FROM tasks
    UNION
    SELECT T.title,
        T.parenttask,
        n + 1
    FROM tasks T
        INNER JOIN recursiveQuery REC ON REC.title = T.parenttask
)
SELECT title AS Task,
    MAX(n) AS PrevCount
FROM recursiveQuery
GROUP BY title
ORDER BY PrevCount ASC;
END;
$$;
--
-- 17) Найти "удачные" для проверок дни. День считается "удачным", 
-- если в нем есть хотя бы N идущих подряд успешных проверки
-- Параметры процедуры: количество идущих подряд успешных проверок N. 
-- Временем проверки считать время начала P2P этапа. 
-- Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных. 
-- При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального. 
-- Формат вывода: список дней
DROP PROCEDURE IF EXISTS FindLuckyDaysForChecks;
CREATE OR REPLACE PROCEDURE FindLuckyDaysForChecks (result_data refcursor, N int) AS $$ BEGIN OPEN result_data FOR WITH data AS(
        SELECT date,
            time,
            status_check,
            LEAD(status_check) OVER (
                ORDER BY date,
                    time
            ) AS next_status_check
        FROM (
                SELECT checks.date,
                    CASE
                        WHEN 100 * xp.XPAmount / tasks.MaxXP >= 80 THEN true
                        ELSE false
                    END AS status_check,
                    p2p.time
                FROM checks
                    JOIN tasks ON checks.task = tasks.title
                    JOIN xp ON checks.id = xp.check_
                    JOIN p2p ON checks.id = p2p.check_
                    AND p2p.state in('Success', 'Failure')
            ) ch
    ),
    data_prev_checks AS (
        SELECT t1.date,
            t1.time,
            t1.status_check,
            t1.next_status_check,
            COUNT (t2.date)
        FROM data t1
            JOIN data t2 on t1.date = t2.date
            AND t1.time <= t2.time
            AND t1.status_check = t2.next_status_check
        GROUP BY t1.date,
            t1.time,
            t1.status_check,
            t1.next_status_check
    )
SELECT date
FROM (
        SELECT date,
            MAX(success_count) AS max_success_count
        FROM (
                SELECT date,
                    count as success_count
                FROM data_prev_checks
                WHERE status_check
            ) success_checks
        GROUP BY date
    ) m
WHERE max_success_count >= N;
END;
$$ LANGUAGE plpgsql;
--
-- 18) Определить пира с наибольшим числом выполненных заданий
-- Формат вывода: ник пира, число выполненных заданий
DROP PROCEDURE IF EXISTS GetPeerWithMaxTasks;
CREATE OR REPLACE PROCEDURE GetPeerWithMaxTasks(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR WITH t AS (
        SELECT c.id,
            c.task,
            c.date,
            c.peer,
            CASE
                WHEN pe.state = 'Success'
                AND (
                    v.state = 'Success'
                    OR v.state IS NULL
                )
                AND xpamount * 100 / maxxp >= 80 THEN 1
                ELSE 0
            END AS successful,
            pe.state AS p2p_state,
            v.state AS verter_state,
            ps.time start_time,
            xpamount * 100 / maxxp AS percentage
        FROM checks c
            LEFT JOIN (
                SELECT check_,
                    time,
                    state
                FROM p2p
                WHERE state = 'Start'
            ) ps ON ps.check_ = c.id
            JOIN (
                SELECT check_,
                    time,
                    state
                FROM p2p
                WHERE state != 'Start'
            ) pe ON pe.check_ = c.id
            LEFT JOIN (
                SELECT check_,
                    time,
                    state
                FROM verter
                WHERE state != 'Start'
            ) v ON v.check_ = c.id
            LEFT JOIN xp ON c.id = xp.check_
            LEFT JOIN tasks t ON c.task = t.title
        ORDER BY date,
            start_time
    )
SELECT DISTINCT peer,
    sum(successful) OVER (PARTITION BY peer) AS XP
FROM t
ORDER BY XP DESC
LIMIT 1;
END;
$$;
--
-- 19) Определить пира с наибольшим количеством XP
-- Формат вывода: ник пира, количество XP
DROP PROCEDURE IF EXISTS GetPeerWithMaxXp;
CREATE OR REPLACE PROCEDURE GetPeerWithMaxXp(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR
SELECT peer,
    sum(xpamount)
FROM xp
    JOIN checks c ON xp.check_ = c.id
GROUP BY peer;
END;
$$;
--
-- 20) Определить пира, который провел сегодня в кампусе больше всего времени
-- Формат вывода: ник пира
DROP PROCEDURE IF EXISTS GetPeerMaxTimeSpent;
CREATE OR REPLACE PROCEDURE GetPeerMaxTimeSpent(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR WITH t AS (
        SELECT *,
            date + time AS datetime
        FROM timetracking
    ),
    cs AS (
        SELECT peer,
            state AS current_state
        FROM t
            JOIN(
                SELECT peer,
                    MAX(datetime) AS datetime
                FROM t
                GROUP BY peer
            ) m USING (peer, datetime)
    )
SELECT DISTINCT peer
FROM (
        SELECT DISTINCT peer,
            date,
            current_state,
            (
                CASE
                    WHEN current_state = 1 THEN to_char(
                        COALESCE(
                            date_trunc('second', LOCALTIME) + sum(time) FILTER (
                                WHERE state = 2
                            ) OVER (PARTITION BY peer, date),
                            date_trunc('second', LOCALTIME)
                        ) - sum(time) FILTER (
                            WHERE state = 1
                        ) OVER (PARTITION BY peer, date),
                        'HH24:MI:SS'
                    )
                    ELSE to_char(
                        sum(time) FILTER (
                            WHERE state = 2
                        ) OVER (PARTITION BY peer, date) - sum(time) FILTER (
                            WHERE state = 1
                        ) OVER (PARTITION BY peer, date),
                        'HH24:MI:SS'
                    )
                END
            ) time_spent
        FROM t
            JOIN cs USING (peer)
        WHERE date = CURRENT_DATE
        ORDER BY time_spent DESC
        LIMIT 1
    ) data;
END;
$$;
--
-- 21) Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
-- Параметры процедуры: время, количество раз N. 
-- Формат вывода: список пиров
DROP PROCEDURE IF EXISTS GetPeerMaxTimeSpent;
CREATE OR REPLACE PROCEDURE GetPeerMaxTimeSpent(result_data refcursor, TM time, N int) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR WITH t AS (
        SELECT DISTINCT peer,
            date,
            MIN(time) OVER (PARTITION BY peer, date) AS arrival_time
        FROM timetracking
        ORDER BY arrival_time
    )
SELECT t1.peer,
    count(t1.peer) AS count
FROM timetracking t1
    JOIN t t2 ON t1.time = t2.arrival_time
    AND t1.date = t2.date
    and t1.peer = t2.peer
WHERE arrival_time < TM
    AND t1.state = 1
GROUP BY t1.peer
HAVING count(t1.peer) > N;
END;
$$;
--
-- 22) Определить пиров, выходивших за последние N дней из кампуса больше M раз
-- Параметры процедуры: количество дней N, количество раз M.
-- Формат вывода: список пиров
DROP PROCEDURE IF EXISTS foo22;
CREATE OR REPLACE PROCEDURE foo22(
        result_data refcursor,
        N int,
        M int
    ) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR
select timetracking.peer
from timetracking
where timetracking.state = 2
    and current_date - timetracking.date <= N
group by peer
HAVING count(*) > M;
END;
$$;
--
-- 23) Определить пира, который пришел сегодня последним
-- Формат вывода: ник пира
DROP PROCEDURE IF EXISTS PeerLastOut;
CREATE OR REPLACE PROCEDURE PeerLastOut(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR
select peer
from timetracking
where date = current_date
    and state = '1'
order by time desc
limit 1;
END;
$$;
--
-- 24) Определить пиров, которые выходили вчера из кампуса больше чем на N минут
-- Параметры процедуры: количество минут N.
-- Формат вывода: список пиров
DROP PROCEDURE IF EXISTS PeersLeftNMinutes;
CREATE OR REPLACE PROCEDURE PeersLeftNMinutes(
        result_data refcursor,
        N int
    ) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR with t1 as (
        select *
        from timetracking
        where state = '1'
            and timetracking.date = current_date - 1
        order by peer,
            time
    ),
    t2 as (
        select *
        from timetracking
        where state = '2'
            and timetracking.date = current_date - 1
        order by peer,
            time
    )
select distinct *
from (
        select t1.peer
        from t1
            join t2 on t1.peer = t2.peer
            and t1.id > t2.id
            and t1.time - t2.time > concat(N, 'minutes')::interval
    ) as temp;
END;
$$;
--
-- 25) Определить для каждого месяца процент ранних входов
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, 
-- приходили в кампус за всё время (будем называть это общим числом входов).
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, 
-- приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов).
-- Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов.
-- Формат вывода: месяц, процент ранних входов
DROP PROCEDURE IF EXISTS foo25;
CREATE OR REPLACE PROCEDURE foo25(result_data refcursor) LANGUAGE plpgsql AS $$ BEGIN OPEN result_data FOR with gs as (
        select generate_series(1, 12) as month_
    ),
    all_count as (
        select date_part('month', timetracking.date) as month_,
            count(*) as count_
        from timetracking
            left join peers on timetracking.peer = peers.nickname
        where timetracking.state = '1'
            and date_part('month', peers.birthday) = date_part('month', timetracking.date)
        group by date,
            birthday
    ),
    early_count as (
        select date_part('month', timetracking.date) as month_,
            count(*) as count_
        from timetracking
            left join peers on timetracking.peer = peers.nickname
        where timetracking.state = '1'
            and date_part('month', peers.birthday) = date_part('month', timetracking.date)
            and timetracking.time < '12:00'
        group by date,
            birthday
    )
select to_char(to_timestamp(temp.month_::text, 'MM'), 'Mon') as month_,
    case
        when temp.count1 = 0 then null
        else temp.count2 * 100 / temp.count1
    end
from (
        select gs.month_,
            case
                when all_count.count_ is null then 0
                else all_count.count_
            end as count1,
            case
                when early_count.count_ is null then 0
                else early_count.count_
            end as count2
        from gs
            left join all_count on all_count.month_ = gs.month_
            left join early_count on early_count.month_ = gs.month_
    ) as temp;
END;
$$;
CALL foo25('data');
fetch all
FROM "data";