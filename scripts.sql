-- Tabla Person
create table Person(
    pid serial primary key,
    firstName character varying(30),
    lastName character varying(30),
    dob date,
    gender character varying(1),
    created_at timestamp,
    updated_at timestamp
);

-- Tabla Patient
create table Patient(
    insurancePlan character varying(30)
) inherits(Person);
alter table Patient add primary key(pid);

-- Tabla Doctor
create table Doctor(
    specialty character varying[50],
    yearsExperience integer,
    salary money not null
) inherits(Person);
alter table Doctor add primary key(pid);

-- Tabla Treatment
create table Treatment(
    tid serial primary key,
    duration integer,
    medicaments character varying[50],
    description character varying(100),
    received_by integer,
    prescribed_by integer,
    created_at timestamp,
    updated_at timestamp
);

-- Tabla Area
create table Area(
    aid serial primary key,
    name character varying(30),
    location character varying(30),
    leaded_by integer,
    created_at timestamp,
    updated_at timestamp
);

-- Referencias
alter table Doctor add column works integer references Area (aid);

alter table Area add constraint leaded_by foreign key(leaded_by) references Doctor(pid);

alter table Treatment add constraint received_by foreign key(received_by) references Patient(pid);

alter table Treatment add constraint prescribed_by foreign key(prescribed_by) references doctor(pid);

-- Fechas
alter table Patient alter column created_at SET default now();
alter table Patient alter column updated_at SET default now();

alter table Doctor alter column created_at SET default now();
alter table Doctor alter column updated_at SET default now();

alter table Treatment alter column created_at SET default now();
alter table Treatment alter column updated_at SET default now();

alter table Area alter column created_at SET default now();
alter table Area alter column updated_at SET default now();

-- Reglas

-- 1.
create rule "Area_Leader" as
on update to Area
where (select works from doctor where pid = new.leaded_by) <> new.aid
do instead select 'Area leader must work on the area';

-- 2.
create rule "Doctor_Salary" as
on update to Doctor
where new.yearsExpierience - 2 >= old.yearsExpierience
do also update Doctor set salary = salary*1.1 where pid = new.pid;

-- 3.
create rule "Patient_Insurance_Insert" as
on insert to Patient
where new.insurancePlan not in ('Unlimited', 'Premium', 'Basic')
do instead select 'Cannot add patient. Insurance plan must be Unlimited, Premium or Basic';

create rule "Patient_Insurance_Update" as
on update to Patient
where new.insurancePlan not in ('Unlimited', 'Premium', 'Basic')
do instead select 'Cannot update patient. Insurance plan must be Unlimited, Premium or Basic';

-- 4.
create rule "Doctor_Area" as
on update to Doctor
where (select leaded_by from area where aid = old.works) = new.pid and old.works <> new.works
do instead select 'Area leader cannot change area without assigning a new area leader.';

-- 5.
/*create rule "Doctor_Specialty" as
on update to Doctor
'General Medicine', 'Traumatology', 'Allergology', 'Radiology',
'Cardiology', 'Gerontology', 'Obstetrics', 'Pediatrics'*/
