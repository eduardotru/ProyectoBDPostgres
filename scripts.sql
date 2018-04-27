-- Tabla Person
create table Person(
    pid serial,
    firstName character varying(30),
    lastName character varying(30),
    dob date,
    gender character varying(1),
    primary key(pid)
);

-- Tabla Patient
create table Patient(
    insurancePlan character varying(30),
    primary key(pid)
) inherits(Person);

-- Tabla Doctor
create table Doctor(
    specialty character varying[50],
    yearsExperience integer,
    salary money not null,
    primary key(pid)
) inherits(Person);

-- Tabla Treatment
create table Treatment(
    tid serial,
    duration integer,
    medicaments character varying[50],
    description character varying(100),
    received_by serial,
    prescribed_by serial,
    primary key(tid)
);

-- Tabla Area
create table Area(
    aid serial,
    name character varying(30),
    location character varying(30),
    leaded_by serial,
    primary key(aid)
);

-- Referencias
alter table Doctor add column works serial references Area (aid);

alter table Area add constraint leaded_by foreign key(leaded_by) references Doctor(pid);

alter table Treatment add constraint received_by foreign key(received_by) references Patient(pid);

alter table Treatment add constraint prescribed_by foreign key(prescribed_by) references doctor(pid);

-- Especialidades/Areas
create table specialties(
    name character varying(30)
);

insert into specialties values('General Medicine');
insert into specialties values('Traumatology');
insert into specialties values('Allergology');
insert into specialties values('Radiology');
insert into specialties values('Cardiology');
insert into specialties values('Gerontology');
insert into specialties values('Obstetrics');
insert into specialties values('Pediatrics');

-- Reglas
-- 1.
create rule "Area_Leader" as
on update to Area
where (select works from doctor where pid = new.leaded_by) <> new.aid
do instead select 'Area leader must work on the area';

-- 2.
create rule "Doctor_Salary" as
on update to Doctor
where new.yearsExperience - 2 >= old.yearsExperience
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
create rule "Doctor_Specialty_Update" as
on update to Doctor
where new.specialty && Array(select * from specialties)
do instead select 'Doctor specialty not recognized.';

create rule "Doctor_Specialty_Insert" as
on insert to Doctor
where new.specialty && Array(select * from specialties)
do instead select 'Doctor specialty not recognized.';

create rule "Hospital_Area_Update" as
on update to Area
where new.name not in (select * from specialties)
do instead select 'Area name not recognized.';

create rule "Hospital_Area_Insert" as
on insert to Area
where new.name not in (select * from specialties)
do instead select 'Area name not recognized.';

-- 6.
create rule "Doctor_Works_Specialty_Update" as
on update to Doctor
where (select name from area where aid = new.works) <> Any(new.specialty)
do instead select 'Doctor cannot work in an area that is not his specialty';

create rule "Doctor_Works_Specialty_Insert" as
on insert to Doctor
where (select name from area where aid = new.works) <> Any(new.specialty)
do instead select 'Doctor cannot work in an area that is not his specialty';

-- 7.
create rule "Premium_Insurance_Insert" as
on insert to Treatment
where (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid) = 'Radiology'
do instead select 'Premium insurance does not cover radiology treatment.';

create rule "Premium_Insurance_Update" as
on update to Treatment
where (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid) = 'Radiology'
do instead select 'Premium insurance does not cover radiology treatment.';

create rule "Basic_Insurance_Insert" as
on insert to Treatment
where (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid) not in ('General Medicine', 'Obstetrics', 'Pediatrics')
do instead select 'Premium insurance does not cover radiology treatment.';

create rule "Basic_Insurance_Update" as
on update to Treatment
where (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid) not in ('General Medicine', 'Obstetrics', 'Pediatrics')
do instead select 'Premium insurance does not cover radiology treatment.';

