-- Aides pour les tests pgTAP : créer des comptes et « se connecter » en
-- tant que l'un d'eux (rôle `authenticated` + claims JWT), comme le fait
-- PostgREST pour une vraie requête.
create schema if not exists tests;

create or replace function tests.create_user(p_email text) returns uuid
language sql as $$
  insert into auth.users (email) values (p_email) returning id
$$;

create or replace function tests.authenticate_as(p_user_id uuid) returns void
language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', p_user_id, 'role', 'authenticated')::text,
    true
  );
end;
$$;

create or replace function tests.authenticate_as_anon() returns void
language plpgsql as $$
begin
  perform set_config('role', 'anon', true);
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
end;
$$;

create or replace function tests.clear_authentication() returns void
language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end;
$$;

grant usage on schema tests to anon, authenticated, service_role;
grant execute on all functions in schema tests to anon, authenticated, service_role;
