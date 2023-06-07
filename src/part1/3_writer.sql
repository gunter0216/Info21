drop procedure if exists export_table(varchar, varchar, varchar);
create or replace procedure export_table(file_name varchar(255),
                                         table_name varchar(255),
                                         delimiter varchar(1))
language plpgsql
as $$
declare
    dir varchar(255) := (select setting as directory
                         from pg_settings
                         where name = 'data_directory') || '/' || file_name;
begin
    EXECUTE format('copy %s to %L with csv delimiter %L header', quote_ident(table_name), dir, delimiter);
end $$;

drop procedure if exists import_table(varchar, varchar, varchar);
create or replace procedure import_table(file_name varchar(255),
                                         table_name varchar(255),
                                         delimiter varchar(1))
language plpgsql
as $$
declare
    dir varchar(255) := (select setting as directory
                         from pg_settings
                         where name = 'data_directory') || '/' || file_name;
begin
    EXECUTE format('copy %s from %L with csv delimiter %L header', quote_ident(table_name), dir, delimiter);
end $$;

create or replace procedure import_checks(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('checks.csv', 'checks', delimiter);
end $$;

create or replace procedure import_friends(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('friends.csv', 'friends', delimiter);
end $$;

create or replace procedure import_p2p(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('p2p.csv', 'p2p', delimiter);
end $$;

create or replace procedure import_peers(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('peers.csv', 'peers', delimiter);
end $$;

create or replace procedure import_recommendations(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('recommendations.csv', 'recommendations', delimiter);
end $$;

create or replace procedure import_tasks(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('tasks.csv', 'tasks', delimiter);
end $$;

create or replace procedure import_timetracking(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('timetracking.csv', 'timetracking', delimiter);
end $$;

create or replace procedure import_tranferredpoints(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('tranferredpoints.csv', 'tranferredpoints', delimiter);
end $$;

create or replace procedure import_verter(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('verter.csv', 'verter', delimiter);
end $$;

create or replace procedure import_xp(delimiter varchar(1)) language plpgsql as $$
begin
    call import_table('xp.csv', 'xp', delimiter);
end $$;

create or replace procedure export_checks(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('checks.csv', 'checks', delimiter);
end $$;

create or replace procedure export_friends(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('friends.csv', 'friends', delimiter);
end $$;

create or replace procedure export_p2p(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('p2p.csv', 'p2p', delimiter);
end $$;

create or replace procedure export_peers(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('peers.csv', 'peers', delimiter);
end $$;

create or replace procedure export_recommendations(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('recommendations.csv', 'recommendations', delimiter);
end $$;

create or replace procedure export_tasks(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('tasks.csv', 'tasks', delimiter);
end $$;

create or replace procedure export_timetracking(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('timetracking.csv', 'timetracking', delimiter);
end $$;

create or replace procedure export_tranferredpoints(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('tranferredpoints.csv', 'tranferredpoints', delimiter);
end $$;

create or replace procedure export_verter(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('verter.csv', 'verter', delimiter);
end $$;

create or replace procedure export_xp(delimiter varchar(1)) language plpgsql as $$
begin
    call export_table('xp.csv', 'xp', delimiter);
end $$;
