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
    received_by integer,
    prescribed_by integer,
    primary key(tid)
);

-- Tabla Area
create table Area(
    aid serial,
    name character varying(30),
    location character varying(30),
    leaded_by integer,
    primary key(aid)
);

-- Referencias
alter table Doctor add column works integer references Area (aid);

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
-- 1. Finished
create rule "Area_Leader" as
on update to Area
where (select works from doctor where pid = new.leaded_by) <> new.aid
do instead select 'Area leader must work on the area';

-- 2.
/*create function increment_salary(integer) returns integer as
'update Doctor set salary = salary*1.1 where pid = $1 returning 1;'
LANGUAGE SQL;*/

Create Procedure increment_salary
    (@doctorID int)
As
Begin
    update Doctor set salary = salary*1.1 where pid = @doctorID;
End

create trigger doctor_salary 
after update of yearsExperience on doctor
for each row
when (old.yearsExperience + 2 <= new.yearsExperience)
execute procedure increment_salary new.pid;

-- 3. Finished
create rule "Patient_Insurance_Insert" as
on insert to Patient
where new.insurancePlan not in ('Unlimited', 'Premium', 'Basic')
do instead select 'Cannot add patient. Insurance plan must be Unlimited, Premium or Basic';

create rule "Patient_Insurance_Update" as
on update to Patient
where new.insurancePlan not in ('Unlimited', 'Premium', 'Basic')
do instead select 'Cannot update patient. Insurance plan must be Unlimited, Premium or Basic';

-- 4. Finished
create rule "Doctor_Area" as
on update to Doctor
where (select leaded_by from area where aid = old.works) = new.pid and old.works <> new.works
do instead select 'Area leader cannot change area without assigning a new area leader.';

-- 5. Finished

create function check_specialties(spec character varying[50]) returns boolean as $$
BEGIN
        FOR i in 1 .. array_upper(spec, 1)
        loop
            if spec[i] not in (select * from specialties) then
                return false;
            end if;
        end loop;
        return true;
END;
$$  LANGUAGE plpgsql;

create rule "Doctor_Specialty_Update" as
on update to Doctor
where not check_specialties(new.specialty)
do instead select 'Doctor specialty not recognized.';

create rule "Doctor_Specialty_Insert" as
on insert to Doctor
where not check_specialties(new.specialty)
do instead select 'Doctor specialty not recognized.';

create rule "Hospital_Area_Update" as
on update to Area
where new.name not in (select * from specialties)
do instead select 'Area name not recognized.';

create rule "Hospital_Area_Insert" as
on insert to Area
where new.name not in (select * from specialties)
do instead select 'Area name not recognized.';

-- 6. Finished
create or replace rule "Doctor_Works_Specialty_Update" as
on update to Doctor
where not (select name from area where aid = new.works) = Any(new.specialty)
do instead select 'Doctor cannot work in an area that is not his specialty';

create or replace rule "Doctor_Works_Specialty_Insert" as
on insert to Doctor
where not (select name from area where aid = new.works) = Any(new.specialty)
do instead select 'Doctor cannot work in an area that is not his specialty';

-- 7. Finished
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
do instead select 'Basic insurance does not cover this treatment.';

create rule "Basic_Insurance_Update" as
on update to Treatment
where (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid) not in ('General Medicine', 'Obstetrics', 'Pediatrics')
do instead select 'Basic insurance does not cover this treatment.';



INSERT INTO patient (firstname, lastname, dob, gender, insuranceplan) 
VALUES ('Lizzie', 'Canamar', '1996-12-26', 'F','Basic'),
('Astrid', 'Carrillo', '1999-09-12', 'F','Unlimited'),
('Dulce', 'Martínez', '1996-04-02', 'F','Premium'),
('Aurora', 'Vega', '1992-10-19', 'F','Basic'),
('Samantha', 'Solis', '1997-06-30', 'F','Premium');

INSERT INTO doctor (firstname, lastname, dob, gender, specialty, yearsExperience, salary) 
VALUES ('Josue', 'Rodriguez', '1976-12-06', 'M','{General Medicine, Radiology}','15','25000'),
('Melissa', 'Carrillo', '1989-12-16', 'F','{General Medicine, Obstetrics}','4','15000'),
('Fatima', 'Carrillo', '1987-02-28', 'F','{Traumatology, Radiology}','6','20000'),
('Guadalupe', 'Salazar', '1972-10-19', 'M','{Allergology, Pediatrics}','20','60000'),
('Ricardo', 'Sevilla', '1970-06-01', 'M','{Gerontology, Cardiology}','22','55000');