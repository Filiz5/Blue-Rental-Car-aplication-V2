\c carrental;

CREATE TABLE IF NOT EXISTS public.roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);
INSERT INTO public.roles(id, "name") VALUES(1, 'ROLE_ADMIN');
INSERT INTO public.roles(id, "name") VALUES(2, 'ROLE_CUSTOMER');