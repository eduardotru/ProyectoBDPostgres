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
    specialty varchar(30) ARRAY[8],
    yearsExperience integer,
    salary money not null,
    primary key(pid)
) inherits(Person);

-- Tabla Treatment
create table Treatment(
    tid serial,
    duration integer,
    medicaments varchar(30) ARRAY[4],
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

-- 1. A doctor can be leader only of the Area he/she works on.
create function area_leader()
returns trigger as $$
begin
    if exists (select * from doctor where pid = new.leaded_by AND doctor.works != new.aid)
        then
        RAISE EXCEPTION 'Area leader must work on the area';
        return null;
    end if;
    return new;
end; $$
LANGUAGE plpgsql;

create trigger Area_Leader_Update
before insert or update on Area
for each row
execute procedure area_leader();

-- 2.When doctor accumulates 2 yrs of experience, receives a salary increment of 10%
create function increment_salary()
returns trigger as $$
begin
    if (old.yearsExperience + 2 <= new.yearsExperience)
    then
        new.salary = old.salary * 1.1;
    end if;
    return new;
end; $$
LANGUAGE plpgsql;

create trigger doctor_salary
before update on doctor
for each row
execute procedure increment_salary();

-- 3. Finished

create function patient_Insurance()
returns trigger as $$
begin
    RAISE EXCEPTION 'Insurance plan must be Unlimited, Premium or Basic';
    return null;
end; $$
LANGUAGE plpgsql;

create trigger "Patient_Insurance_Insert"
before insert or update on Patient FOR EACH
ROW WHEN (NEW.insurancePlan not in ('Unlimited', 'Premium', 'Basic'))
execute procedure patient_Insurance();

-- 4. Finished
create function doctor_area()
returns trigger as $$
begin
    if ((select leaded_by from area where aid = old.works) = new.pid and old.works <> new.works)
        then
        RAISE EXCEPTION 'Area leader cannot change area without assigning a new area leader.';
        return null;
    end if;
    return new;
end; $$
LANGUAGE plpgsql;

create trigger "Doctor_Area"
before update on Doctor
FOR EACH ROW
execute procedure doctor_area();


-- 5. Finished
create function check_specialties() returns trigger as $$
BEGIN
        FOR i in 1 .. array_upper(new.specialty, 1)
        loop
            if new.specialty[i] not in (select * from specialties) then
                raise exception 'Doctor specialty not recognized.';
            end if;
        end loop;
        return new;
END;
$$  LANGUAGE plpgsql;

create trigger Doctor_Specialty_Update
before update or insert on Doctor
for each row
execute procedure check_specialties();

create function check_area() returns trigger as $$
BEGIN
        if new.name not in (select * from specialties) then
            raise exception 'Area name not recognized.';
        end if;
        return new;
END;
$$  LANGUAGE plpgsql;

create trigger Hospital_Area
before update or insert on Area
for each row
execute procedure check_area();

-- 6. Finished

create function check_works_specialty() returns trigger as $$
BEGIN
        if not (select name from area where aid = new.works) = Any(new.specialty) then
            raise exception 'Doctor cannot work in an area that is not her/his specialty';
        end if;
        return new;
END;
$$  LANGUAGE plpgsql;

create trigger Doctor_Works_Specialty
before update or insert on Doctor
for each row
execute procedure check_works_specialty();

-- 7. Finished
create function check_premium_insurance() returns trigger as $$
BEGIN
        if (select insurancePlan from patient where pid = new.received_by) = 'Premium' and (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid)  = 'Radiology' then
            raise exception 'Premium insurance does not cover radiology treatment.';
        end if;
        return new;
END;
$$  LANGUAGE plpgsql;

create trigger Premium_Insurance
before update or insert on Treatment
for each row
execute procedure check_premium_insurance();



create function check_basic_insurance() returns trigger as $$
BEGIN
        if (select insurancePlan from patient where pid = new.received_by) = 'Basic' and (select a.name from area a, doctor d where new.prescribed_by = d.pid and d.works = a.aid) not in ('General Medicine', 'Obstetrics', 'Pediatrics') then
            raise exception 'Basic insurance does not cover this treatment.';
        end if;
        return new;
END;
$$  LANGUAGE plpgsql;

create trigger Basic_Insurance
before update or insert on Treatment
for each row
execute procedure  check_basic_insurance();

INSERT INTO patient (firstname, lastname, dob, gender, insuranceplan)
VALUES ('Lizzie', 'Canamar', '1996-12-26', 'F','Basic'),
('Astrid', 'Carrillo', '1999-09-12', 'F','Premium'),
('Dulce', 'Martínez', '1996-04-02', 'F','Unlimited'),
('Aurora', 'Vega', '1992-10-19', 'F','Basic'),
('Samantha', 'Solis', '1997-06-30', 'F','Premium'),
('Zaid', 'Solis', '1998-07-29', 'M','Unlimited'),
('Cecilia', 'Ramos', '1995-01-04', 'F','Unlimited'),
('Carlos', 'Reynosa', '1999-04-14', 'M','Unlimited'),
('Oralia', 'Cardenas', '1979-11-24', 'F','Basic'),
('Guadalupe', 'Cardenas', '1978-05-10', 'F','Basic'),
('Nancy', 'Salazar', '1988-09-15', 'F','Basic');

INSERT INTO area (name, location)
VALUES ('General Medicine','Area 1'),
('Obstetrics','Area 1'),
('Traumatology','Area 1'),
('Allergology','Area 1'),
('Radiology','Area 1'),
('Cardiology','Area 1'),
('Gerontology','Area 1'),
('Pediatrics','Area 1');

INSERT INTO doctor (firstname, lastname, dob, gender, specialty, yearsExperience, salary)
VALUES ('Josue', 'Rodriguez', '1976-12-06', 'M','{"General Medicine", "Traumatology"}','15','25000'),
('Melissa', 'Carrillo', '1989-12-16', 'F','{"General Medicine", "Obstetrics"}','4','15000'),
('Fatima', 'Carrillo', '1987-02-28', 'F','{"Traumatology", "Radiology"}','6','20000'),
('Guadalupe', 'Salazar', '1972-10-19', 'M','{"Allergology", "Pediatrics"}','20','60000'),
('Ricardo', 'Sevilla', '1970-06-01', 'M','{"Gerontology", "Radiology"}','22','55000'),
('Tamara', 'Cavazos', '1982-09-20', 'F','{"Cardiology", "Pediatrics"}','6','60000'),
('Guillermo', 'Cavazos', '1979-06-27', 'F','{"Gerontology", "Traumatology"}','8','70000'),
('Esther', 'Salinas', '1970-05-15', 'F','{"Obstetrics", "Pediatrics"}','18','90000'),
('Salma', 'Valente', '1973-06-16', 'F','{"Obstetrics", "General Medicine"}','20','80000'),
('Sandra', 'Villanueva', '1972-07-17', 'F','{"Obstetrics", "General Medicine"}','20','88000'),
('Susana', 'Villarreal', '1971-08-18', 'F','{"Traumatology", "General Medicine"}','21','85000');

--Add works to doctors
UPDATE doctor SET works = '1' WHERE pid = '12';
UPDATE doctor SET works = '2' WHERE pid = '13';
UPDATE doctor SET works = '3' WHERE pid = '14';
UPDATE doctor SET works = '4' WHERE pid = '15';
UPDATE doctor SET works = '5' WHERE pid = '16';
UPDATE doctor SET works = '6' WHERE pid = '17';
UPDATE doctor SET works = '7' WHERE pid = '18';
UPDATE doctor SET works = '8' WHERE pid = '19';
UPDATE doctor SET works = '1' WHERE pid = '20';
UPDATE doctor SET works = '2' WHERE pid = '21';
UPDATE doctor SET works = '3' WHERE pid = '22';

--Add leader to area 
update area set leaded_by = '12' where aid = '1';
update area set leaded_by = '13' where aid = '2';
update area set leaded_by = '14' where aid = '3';
update area set leaded_by = '15' where aid = '4';
update area set leaded_by = '16' where aid = '5';
update area set leaded_by = '17' where aid = '6';
update area set leaded_by = '18' where aid = '7';

INSERT INTO treatment (duration, medicaments, description, received_by, prescribed_by)
VALUES ('7', '{"Amoxicilin", "Ibuprofen"}','Cada 8 hrs por 7 días','2','12'),
('10', '{"Loratadine", "Ibuprofen"}','Cada 5 hrs por 3 días','4','13');

/*--Insert no valido
INSERT INTO treatment (duration, medicaments, description, received_by, prescribed_by)
VALUES ('7', '{Amoxicilin, Ibuprofen}','Cada 8 hrs por 7 días','9','18');
*/
