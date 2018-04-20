-- Tipo Person
create type person_t as (
    pid integer,
    firstName character varying(30),
    lastName character varying(30),
    dob date,
    gender character varying(1)
);

-- Tabla Person
create table Person of person_t(primary key(pid));

-- Tabla Patient
create table Patient(
    insurancePlan character varying(30)
) inherits(Person);
alter table Patient add primary key(pid);

-- Tabla Doctor
create table Doctor(
    specialty character varying(50),
    yearsExpierience integer
) inherits(Person);
alter table Doctor add primary key(pid);

-- Tipo Treatment
create type treatment_t as (
    tid integer,
    duration integer,
    medicaments character varying[50],
    description character varying(100),
    received_by integer,
    prescribed_by integer
);

-- Tabla Treatment
create table Treatment of treatment_t(primary key(tid));

-- Tipo Area
create type area_t as (
    aid integer,
    name character varying(30),
    location character varying(30),
    leaded_by integer
);

-- Tabla Area
create table Area of area_t(primary key(aid));

-- Referencias
alter table Doctor add column works integer references Area (aid);

alter table Area add constraint leaded_by foreign key(leaded_by) references Doctor(pid);

alter table Treatment add constraint received_by foreign key(received_by) references Patient(pid);

alter table Treatment add constraint prescribed_by foreign key(prescribed_by) references doctor(pid);