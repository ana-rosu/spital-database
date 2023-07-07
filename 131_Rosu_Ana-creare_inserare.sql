-------------------------------------------CREARE-TABELE-------------------------------------------

--ADRESE--

create table adrese (
    id number(4) constraint pk_adr primary key,
    strada varchar2(25),
    numar number(3),
    oras varchar(15) not null,
    judet varchar(15)
);

--PACIENTI--

create table pacienti (
    id number(3) constraint pk_pac primary key,
    nume varchar2(10) not null,
    prenume varchar2(10) not null,
    data_nasterii date,
    sex varchar2(1),
    id_adresa number(4) not null,
    constraint fk_pac foreign key(id_adresa) references adrese
);

--SPITALE--

create table spitale (
    id number(3) primary key,
    nume varchar2(40) not null,
    data_infintarii date,
    id_adresa number(4) unique,
    constraint fk_sp foreign key(id_adresa) references adrese
);

--SECTII--

create table sectii (
    id number(4) primary key,
    nume varchar2(40) not null,
    nr_paturi number(3),
    id_sef number(3) unique,
    id_spital number(3),
    foreign key(id_spital) references spitale(id)
);

--ANGAJATI--
--un angajat poate fi de un singur tip: fie medic, fie sofer

--pentru a obtine asta, creez o tabela care contine diferitele tipuri de angajati
--pe care sistemul le va permite
create table tip_ang (
    id varchar(5) primary key
);
insert into tip_ang values ('Medic');
insert into tip_ang values ('Sofer');
--acum voi adauga in tabela angajati coloana id_tip_ang;
--fiecarui angajat trebuie sa ii fie asignat un tip => not null;
--adaug constrangere unique(id, id_tip_ang) ca sa pot seta o cheie straina
--in subtabele care sa referentieze acest tuplu;
create table angajati (
    id number(4) primary key,
    id_tip_ang varchar(5) references tip_ang(id) not null,
    nume varchar2(8) not null,
    prenume varchar2(12) not null,
    data_angajarii date default sysdate,
    salariu number(8,2),
    constraint ang_min_sal check (salariu > 0),
    constraint ang_alt_pk unique (id, id_tip_ang)
);
--subtabelele vor avea o cheie straina care sa referentieze angajatul
--dar in loc sa referentieze doar angajat(id) va referentia tuplul (id, id_tip_ang)
--in felul acesta e garantat ca angajatul va fi de un singur tip
--si ca pot avea date doar in subtabela corespunzatoare pt acel tip

--MEDICI--

create table medici (
    id number(4) primary key,
    id_tip_ang varchar(5) default 'Medic' check (id_tip_ang = 'Medic'),
    tip varchar2(10),
    id_sectie number(4),
    foreign key(id_sectie) references sectii(id),
    foreign key(id, id_tip_ang) references angajati(id, id_tip_ang)
);
select * from medici;
--acum ca am creat tabela medici, care la randul ei referentia tabela sectii
--pot altera tabela sectii sa aiba cheie straina catre id-ul unui medic,
--reprezentand seful pe sectia respectiva
alter table sectii add (constraint sect_sef_fk foreign key (id_sef) references medici(id));
alter table sectii drop constraint sect_sef_fk;

--SOFERI--

create table soferi (
    id number(4) primary key,
    id_tip_ang varchar(5) default 'Sofer' check (id_tip_ang = 'Sofer'),
    id_spital number(3),
    foreign key(id_spital) references spitale(id),
    foreign key(id, id_tip_ang) references angajati(id, id_tip_ang)
);


create view medici_complet as
select a.*, m.tip, m.id_sectie, s.nume as nume_sectie
from angajati a inner join medici m
on a.id = m.id
inner join sectii s
on m.id_sectie = s.id;

--select * from medici_complet;

create view soferi_complet as
select angajati.*, id_spital, spitale.nume as nume_spital
from angajati inner join soferi
on angajati.id = soferi.id
inner join spitale
on soferi.id_spital = spitale.id;

--AMBULANTE--

create table ambulante (
    id number(3) primary key,
    nr_inmatriculare varchar2(8) not null,
    capacitate number(1),
    id_spital number(3),
    foreign key(id_spital) references spitale(id)
);
--SERVICII_AMBULANTA--

create table servicii_amb (
    id_sofer number(4),
    id_pacient number(3),
    id_ambulanta number(3),
    data_serviciu date default sysdate,
    motiv varchar2(30) not null,
    constraint serv_amb_pk primary key(id_sofer, id_pacient, id_ambulanta),
    constraint serv_amb_fk_sof foreign key(id_sofer) references soferi(id),
    constraint serv_amb_fk_pac foreign key(id_pacient) references pacienti(id),
    constraint serv_amb_fk_amb foreign key(id_ambulanta) references ambulante(id)
);

--MEDICAMENTE--

create table medicamente (
    id number(4) primary key,
    nume varchar(20),
    companie varchar(20),
    data_expirarii date
);
alter table medicamente
modify nume not null;
desc medicamente;
--DIAGNOSTICE--

create table diagnostice (
    id number(4) primary key,
    nume varchar2(25) not null,
    tip_tratament varchar2(25),
    constraint uc_diag_nume_tip UNIQUE (nume, tip_tratament)
);

--RETETE--

create table retete (
    id_diagnostic number(4),
    id_medicament number(4),
    doza varchar2(20),
    durata varchar2(20),
    constraint ret_pk primary key(id_diagnostic, id_medicament),
    constraint ret_fk_diag foreign key(id_diagnostic) references diagnostice(id),
    constraint ret_fk_mdm foreign key(id_medicament) references medicamente(id)
);
--CONSULTATII--

create table consultatii (
    id number(4) primary key,
    data_examinarii date default sysdate,
    id_medic number(4) not null,
    id_pacient number(3) not null,
    id_diagnostic number(4) not null,
    constraint cons_fk_med foreign key(id_medic) references medici(id),
    constraint cons_fk_pac foreign key(id_pacient) references pacienti(id),
    constraint cons_fk_diag foreign key(id_diagnostic) references diagnostice(id)
);

--FACTURI--

create table facturi (
    id number(5) primary key,
    suma number(6) not null,
    mod_plata varchar2(5),
    id_consultatie number(4) not null,
    constraint fact_fk_cons foreign key(id_consultatie) references consultatii(id),
    constraint fact_uniq_cons unique(id_consultatie)
);

-------------------------------------------INSERARI-------------------------------------------

-- INSERARE ADRESE --
create sequence seq_adr
start with 1200
maxvalue 9999
nocycle
nocache;

insert into adrese values (seq_adr.nextval, 'Str. Varsatorului', 2, 'Magurele', 'Ilfov');
insert into adrese values (seq_adr.nextval, 'Calea Floreasca', 8, 'Sector 1', 'Bucuresti');
insert into adrese values (seq_adr.nextval, 'Bdul Independentei', 1, 'Iasi', 'Iasi');
insert into adrese values (seq_adr.nextval, 'Bdul Corneliu Coposu', 24, 'Sibiu', 'Sibiu');
insert into adrese values (seq_adr.nextval, 'Bdul 1 Decembrie 1918', 21, 'Suceava', 'Suceava');
insert into adrese values (seq_adr.nextval, 'Str. Dornei', 114, 'Sector 1', 'Bucuresti');
insert into adrese values (seq_adr.nextval, 'Str. Rasadnitei', 8, 'Sector 6', 'Bucuresti');
insert into adrese values (seq_adr.nextval, 'Bd. Ion Mihalache', 37, 'Sector 1', 'Bucuresti');
insert into adrese values (seq_adr.nextval, 'Strada Victoriei', 10, 'Bucure?ti', 'Ilfov');
insert into adrese values (seq_adr.nextval, 'Strada Libertă?ii', 15, 'Cluj-Napoca', 'Cluj');
insert into adrese values (seq_adr.nextval, 'Strada Unirii', 5, 'Timi?oara', 'Timi?');
insert into adrese values (seq_adr.nextval, 'Bulevardul Revolu?iei', 7, 'Ia?i', 'Ia?i');
insert into adrese values (seq_adr.nextval, 'Strada Mihai Viteazu', 23, 'Craiova', 'Dolj');
insert into adrese values (seq_adr.nextval, 'Strada Eroilor', 12, 'Constan?a', 'Constan?a');
insert into adrese values (seq_adr.nextval, 'Bulevardul Decebal', 18, 'Bra?ov', 'Bra?ov');
insert into adrese values (seq_adr.nextval, 'Strada Dimitrie Cantemir', 9, 'Ploie?ti', 'Prahova');
insert into adrese values (seq_adr.nextval, 'Aleea Gheorghe Lazăr', 4, 'Oradea', 'Bihor');
insert into adrese values (seq_adr.nextval, 'Bdl Tudor Vladimirescu', 14, 'Arad', 'Arad');
insert into adrese values (seq_adr.nextval, 'Strada Avram Iancu', 20, 'Târgu Mure?', 'Mure?');
insert into adrese values (seq_adr.nextval, 'Strada Vasile Alecsandri', 8, 'Sibiu', 'Sibiu');
insert into adrese values (seq_adr.nextval, 'Bulevardul Carol I', 17, 'Gala?i', 'Gala?i');
insert into adrese values (seq_adr.nextval, 'Strada Nicolae Bălcescu', 3, 'Boto?ani', 'Boto?ani');
insert into adrese values (seq_adr.nextval, 'Strada 1 Decembrie', 11, 'Bacău', 'Bacău');
insert into adrese values (seq_adr.nextval, 'Bdl Alexandru Ioan Cuza', 22, 'Pite?ti', 'Arges');
insert into adrese values (seq_adr.nextval, 'Strada ?tefan cel Mare', 6, 'Brăila', 'Brăila');
insert into adrese values (seq_adr.nextval, 'Strada Vasile Pârvan', 13, 'Rm Vâlcea', 'Vâlcea');
insert into adrese values (seq_adr.nextval, 'Bulevardul Iuliu Maniu', 19, 'Suceava', 'Suceava');
insert into adrese values (seq_adr.nextval, 'Strada Mihai Eminescu', 15, 'Ia?i', 'Ia?i');
insert into adrese values (seq_adr.nextval, 'Strada Avram Iancu', 7, 'Cluj-Napoca', 'Cluj');
insert into adrese values (seq_adr.nextval, 'Strada Tudor Vladimirescu', 20, 'Timi?oara', 'Timi?');
insert into adrese values (seq_adr.nextval, 'Strada 1 Decembrie', 5, 'Craiova', 'Dolj');
insert into adrese values (seq_adr.nextval, 'Strada Unirii', 12, 'Oradea', 'Bihor');

-- INSERARE PACIENTI --
create  sequence seq_pac
start with 100
maxvalue 999
nocycle
nocache;

insert into pacienti values (seq_pac.nextval, 'Popescu', 'Ana', to_date('12-05-1990', 'DD-MM-YYYY'), 'F', 1203);
insert into pacienti values (seq_pac.nextval, 'Ionescu', 'Mihai', to_date('21-08-1985', 'DD-MM-YYYY'), 'M', 1209);
insert into pacienti values (seq_pac.nextval, 'Apostol', 'Maria', to_date('03-11-1992', 'DD-MM-YYYY'), 'F', 1210);
insert into pacienti values (seq_pac.nextval, 'Radu', 'Ion', to_date('17-02-1978', 'DD-MM-YYYY'), 'M', 1222);
insert into pacienti values (seq_pac.nextval, 'Dumitru', 'Elena', to_date('25-06-1982', 'DD-MM-YYYY'), 'F', 1202);
insert into pacienti values (seq_pac.nextval, 'Stancu', 'Andrei', to_date('08-03-1996', 'DD-MM-YYYY'), 'M', 1212);
insert into pacienti values (seq_pac.nextval, 'Constantin', 'Laura', to_date('30-09-1994', 'DD-MM-YYYY'), 'F', 1220);
insert into pacienti values (seq_pac.nextval, 'Florescu', 'Alexandru', to_date('14-07-1989', 'DD-MM-YYYY'), 'M', 1208);
insert into pacienti values (seq_pac.nextval, 'Gheorghe', 'Ioana', to_date('19-04-1991', 'DD-MM-YYYY'), 'F', 1227);
insert into pacienti values (seq_pac.nextval, 'Stan', 'Daniel', to_date('07-12-1980', 'DD-MM-YYYY'), 'M', 1200);
insert into pacienti values (seq_pac.nextval, 'Vasilescu', 'Cristina', to_date('29-01-1987', 'DD-MM-YYYY'), 'F', 1205);
insert into pacienti values (seq_pac.nextval, 'Marin', 'Adrian', to_date('11-10-1984', 'DD-MM-YYYY'), 'M', 1222);
insert into pacienti values (seq_pac.nextval, 'Dobre', 'Georgiana', to_date('02-02-1993', 'DD-MM-YYYY'), 'F', 1201);
insert into pacienti values (seq_pac.nextval, 'Munteanu', 'Sorin', to_date('15-11-1979', 'DD-MM-YYYY'), 'M', 1202);
insert into pacienti values (seq_pac.nextval, 'Neagu', 'Andreea', to_date('28-07-1995', 'DD-MM-YYYY'), 'F', 1203);
insert into pacienti values (seq_pac.nextval, 'Diaconu', 'Dumitru', to_date('04-04-1986', 'DD-MM-YYYY'), 'M', 1210);
insert into pacienti values (seq_pac.nextval, 'Georgescu', 'Elena', to_date('22-01-1981', 'DD-MM-YYYY'), 'F', 1209);
insert into pacienti values (seq_pac.nextval, 'Stoica', 'Marius', to_date('05-09-1997', 'DD-MM-YYYY'), 'M', 1207);
insert into pacienti values (seq_pac.nextval, 'Pavel', 'Andreea', to_date('11-06-1990', 'DD-MM-YYYY'), 'F', 1206);
insert into pacienti values (seq_pac.nextval, 'Gavril', 'Iulia', to_date('27-03-1983', 'DD-MM-YYYY'), 'F', 1204);
insert into pacienti values (seq_pac.nextval, 'Voinea', 'Ionut', to_date('09-12-1977', 'DD-MM-YYYY'), 'M', 1205);
insert into pacienti values (seq_pac.nextval, 'Radulescu', 'Simona', to_date('17-10-1992', 'DD-MM-YYYY'), 'F', 1208);
insert into pacienti values (seq_pac.nextval, 'Barbu', 'Gheorghe', to_date('13-02-1988', 'DD-MM-YYYY'), 'M', 1211);
insert into pacienti values (seq_pac.nextval, 'Iordache', 'Catalina', to_date('26-09-1980', 'DD-MM-YYYY'), 'F', 1213);
insert into pacienti values (seq_pac.nextval, 'Grosu', 'Adrian', to_date('02-07-1987', 'DD-MM-YYYY'), 'M', 1212);
insert into pacienti values (seq_pac.nextval, 'Nistor', 'Elena', to_date('16-03-1993', 'DD-MM-YYYY'), 'F', 1215);
insert into pacienti values (seq_pac.nextval, 'Iancu', 'Mihai', to_date('30-12-1984', 'DD-MM-YYYY'), 'M', 1214);
insert into pacienti values (seq_pac.nextval, 'Matei', 'Ana', to_date('19-01-1989', 'DD-MM-YYYY'), 'F', 1211);
insert into pacienti values (seq_pac.nextval, 'Florea', 'Alexandru', to_date('04-10-1978', 'DD-MM-YYYY'), 'M', 1217);
insert into pacienti values (seq_pac.nextval, 'Dinu', 'Maria', to_date('15-06-1982', 'DD-MM-YYYY'), 'F', 1219);
insert into pacienti values (seq_pac.nextval, 'Stefan', 'Vasile', to_date('29-03-1996', 'DD-MM-YYYY'), 'M', 1218);
insert into pacienti values (seq_pac.nextval, 'Sandu', 'Andreea', to_date('03-08-1994', 'DD-MM-YYYY'), 'F', 1210);
insert into pacienti values (seq_pac.nextval, 'Gheorghiu', 'Adrian', to_date('12-11-1989', 'DD-MM-YYYY'), 'M', 1216);
insert into pacienti values (seq_pac.nextval, 'Dumitrache', 'Ioana', to_date('23-02-1991', 'DD-MM-YYYY'), 'F', 1220);
insert into pacienti values (seq_pac.nextval, 'Mihai', 'Marian', to_date('06-09-1980', 'DD-MM-YYYY'), 'M', 1221);
insert into pacienti values (seq_pac.nextval, 'Niculae', 'Elena', to_date('20-07-1987', 'DD-MM-YYYY'), 'F', 1222);
insert into pacienti values (seq_pac.nextval, 'Cristea', 'Cristian', to_date('03-03-1995', 'DD-MM-YYYY'), 'M', 1223);
insert into pacienti values (seq_pac.nextval, 'Marinescu', 'Raluca', to_date('16-12-1986', 'DD-MM-YYYY'), 'F', 1224);
insert into pacienti values (seq_pac.nextval, 'Tudor', 'Andrei', to_date('28-10-1992', 'DD-MM-YYYY'), 'M', 1225);
insert into pacienti values (seq_pac.nextval, 'Dobre', 'Gabriela', to_date('12-02-1993', 'DD-MM-YYYY'), 'F', 1226);
insert into pacienti values (seq_pac.nextval, 'Stanciu', 'Mihai', to_date('25-09-1979', 'DD-MM-YYYY'), 'M', 1227);
insert into pacienti values (seq_pac.nextval, 'Pop', 'Cristina', to_date('07-06-1995', 'DD-MM-YYYY'), 'F', 1220);
insert into pacienti values (seq_pac.nextval, 'Gheorghe', 'Andrei', to_date('21-03-1983', 'DD-MM-YYYY'), 'M', 1200);
insert into pacienti values (seq_pac.nextval, 'Muntean', 'Elena', to_date('02-12-1981', 'DD-MM-YYYY'), 'F', 1201);
insert into pacienti values (seq_pac.nextval, 'Dinca', 'George', to_date('15-08-1997', 'DD-MM-YYYY'), 'M', 1231);
insert into pacienti values (seq_pac.nextval, 'Popescu', 'Roxana', to_date('28-05-1990', 'DD-MM-YYYY'), 'F', 1230);
insert into pacienti values (seq_pac.nextval, 'Ionescu', 'Mihai', to_date('08-08-1985', 'DD-MM-YYYY'), 'M', 1229);
insert into pacienti values (seq_pac.nextval, 'Apostol', 'Maria', to_date('19-11-1992', 'DD-MM-YYYY'), 'F', 1228);
insert into pacienti values (seq_pac.nextval, 'Radu', 'Ion', to_date('01-02-1978', 'DD-MM-YYYY'), 'M', 1228);
insert into pacienti values (seq_pac.nextval, 'Dumitru', 'Elena', to_date('13-06-1982', 'DD-MM-YYYY'), 'F', 1227);
insert into pacienti values (seq_pac.nextval, 'Stancu', 'Andrei', to_date('26-03-1996', 'DD-MM-YYYY'), 'M', 1226);
insert into pacienti values (seq_pac.nextval, 'Constantin', 'Laura', to_date('09-10-1994', 'DD-MM-YYYY'), 'F', 1225);
insert into pacienti values (seq_pac.nextval, 'Florescu', 'Alexandru', to_date('23-07-1989', 'DD-MM-YYYY'), 'M', 1224);
insert into pacienti values (seq_pac.nextval, 'Gheorghe', 'Ioana', to_date('05-05-1991', 'DD-MM-YYYY'), 'F', 1223);
insert into pacienti values (seq_pac.nextval, 'Stan', 'Daniel', to_date('18-12-1980', 'DD-MM-YYYY'), 'M', 1222);
insert into pacienti values (seq_pac.nextval, 'Vasilescu', 'Cristina', to_date('30-01-1987', 'DD-MM-YYYY'), 'F', 1221);
insert into pacienti values (seq_pac.nextval, 'Marin', 'Adrian', to_date('11-10-1984', 'DD-MM-YYYY'), 'M', 1220);
insert into pacienti values (seq_pac.nextval, 'Dobre', 'Georgiana', to_date('24-02-1993', 'DD-MM-YYYY'), 'F', 1219);
insert into pacienti values (seq_pac.nextval, 'Munteanu', 'Sorin', to_date('08-12-1979', 'DD-MM-YYYY'), 'M', 1218);
insert into pacienti values (seq_pac.nextval, 'Neagu', 'Andreea', to_date('21-07-1995', 'DD-MM-YYYY'), 'F', 1217);
insert into pacienti values (seq_pac.nextval, 'Diaconu', 'Dumitru', to_date('04-04-1986', 'DD-MM-YYYY'), 'M', 1216);
insert into pacienti values (seq_pac.nextval, 'Georgescu', 'Elena', to_date('17-01-1981', 'DD-MM-YYYY'), 'F', 1215);
insert into pacienti values (seq_pac.nextval, 'Stoica', 'Marius', to_date('30-08-1997', 'DD-MM-YYYY'), 'M', 1214);
insert into pacienti values (seq_pac.nextval, 'Pavel', 'Andreea', to_date('13-06-1990', 'DD-MM-YYYY'), 'F', 1213);
insert into pacienti values (seq_pac.nextval, 'Gavril', 'Iulia', to_date('27-03-1983', 'DD-MM-YYYY'), 'F', 1212);
insert into pacienti values (seq_pac.nextval, 'Voinea', 'Ionut', to_date('09-12-1977', 'DD-MM-YYYY'), 'M', 1211);
insert into pacienti values (seq_pac.nextval, 'Radulescu', 'Simona', to_date('22-10-1992', 'DD-MM-YYYY'), 'F', 1210);
insert into pacienti values (seq_pac.nextval, 'Barbu', 'Gheorghe', to_date('06-02-1988', 'DD-MM-YYYY'), 'M', 1209);
insert into pacienti values (seq_pac.nextval, 'Iordache', 'Catalina', to_date('19-09-1980', 'DD-MM-YYYY'), 'F', 1208);
insert into pacienti values (seq_pac.nextval, 'Grosu', 'Adrian', to_date('03-07-1987', 'DD-MM-YYYY'), 'M', 1207);
insert into pacienti values (seq_pac.nextval, 'Nistor', 'Elena', to_date('17-03-1993', 'DD-MM-YYYY'), 'F', 1206);
insert into pacienti values (seq_pac.nextval, 'Iancu', 'Mihai', to_date('01-01-1985', 'DD-MM-YYYY'), 'M', 1205);
insert into pacienti values (seq_pac.nextval, 'Matei', 'Ana', to_date('21-01-1989', 'DD-MM-YYYY'), 'F', 1204);
insert into pacienti values (seq_pac.nextval, 'Florea', 'Alexandru', to_date('05-10-1978', 'DD-MM-YYYY'), 'M', 1203);
insert into pacienti values (seq_pac.nextval, 'Dinu', 'Maria', to_date('16-06-1982', 'DD-MM-YYYY'), 'F', 1202);
insert into pacienti values (seq_pac.nextval, 'Stefan', 'Vasile', to_date('29-03-1996', 'DD-MM-YYYY'), 'M', 1201);
insert into pacienti values (seq_pac.nextval, 'Sandu', 'Andreea', to_date('12-08-1994', 'DD-MM-YYYY'), 'F', 1200);

-- INSERARE SPITALE --
create  sequence seq_sp
start with 200
increment by 1
maxvalue 999
nocycle
nocache;

insert into spitale values (seq_sp.nextval, 'SPITALUL JUD DE URGENTA SF. IOAN CEL NOU', to_date('08-IUN-1997'), 1204);
insert into spitale values (seq_sp.nextval, 'SPITALUL CLINIC JUD DE URGENTA SIBIU', to_date('20-IAN-1980'), 1203);
insert into spitale values (seq_sp.nextval, 'SPITALUL CLINIC DE URGENTA FLOREASCA',to_date('30-APR-2004'), 1201);
insert into spitale values (seq_sp.nextval, 'SPITALUL JUD DE URGENTA SF. SPIRIDON',to_date('02-MAI-2002'), 1202);
insert into spitale values (seq_sp.nextval, 'SPITALUL CLINIC SF. MARIA', to_date('13-OCT-1950'), 1207);
select * from spitale;
-- INSERARE SECTII --
create sequence seq_sec
start with 2000
nocycle
nocache;

insert into sectii values (seq_sec.nextval, 'Cardiologie', 20, null, 200);
insert into sectii values (seq_sec.nextval, 'Ortopedie', 15, null, 201);
insert into sectii values (seq_sec.nextval, 'Ginecologie', 25, null, 202);
insert into sectii values (seq_sec.nextval, 'Neurologie', 30, null, 200);
insert into sectii values (seq_sec.nextval, 'Pediatrie', 40, null, 204);
insert into sectii values (seq_sec.nextval, 'Endocrinologie', 18, null, 205);
insert into sectii values (seq_sec.nextval, 'Oftalmologie', 12, null, 201);
insert into sectii values (seq_sec.nextval, 'Dermatologie', 16, null, 202);
insert into sectii values (seq_sec.nextval, 'Urologie', 22, null, 200);

insert into sectii values (seq_sec.nextval, 'Oncologie', 10, null, 200);
insert into sectii values (seq_sec.nextval, 'Pneumologie', 20, null, 201);
insert into sectii values (seq_sec.nextval, 'Cardiologie', 16, null, 200);
insert into sectii values (seq_sec.nextval, 'Neurologie', 32, null, 200);


-- INSERARE MEDICI --
create sequence seq_med
start with 1400 
maxvalue 9990
nocycle
nocache;

insert into angajati values (seq_med.nextval, 'Medic', 'Popescu', 'Ioan', to_date('12-03-2008', 'DD-MM-YYYY'), 80000);
insert into medici(id, tip, id_sectie) values (seq_med.currval, 'rezident', 2000);

insert into angajati values (seq_med.nextval, 'Medic', 'Ionescu', 'Ana', to_date('05-07-2010', 'DD-MM-YYYY'), 75000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2001);

insert into angajati values (seq_med.nextval, 'Medic', 'Popa', 'Maria', to_date('20-09-2012', 'DD-MM-YYYY'), 90000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2002);

insert into angajati values (seq_med.nextval, 'Medic', 'Vasile', 'Mihai', to_date('08-04-2015', 'DD-MM-YYYY'), 82000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2004);

insert into angajati values (seq_med.nextval, 'Medic', 'George', 'Elena', to_date('16-11-2013', 'DD-MM-YYYY'), 78000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2005);

insert into angajati values (seq_med.nextval, 'Medic', 'Dumitru', 'Andrei', to_date('30-01-2016', 'DD-MM-YYYY'), 85000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2006);

insert into angajati values (seq_med.nextval, 'Medic', 'Costea', 'Ioana', to_date('14-08-2014', 'DD-MM-YYYY'), 76000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2007);

insert into angajati values (seq_med.nextval, 'Medic', 'Stanescu', 'Adrian', to_date('10-06-2011', 'DD-MM-YYYY'), 92000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2011);

insert into angajati values (seq_med.nextval, 'Medic', 'Iordache', 'Cristina', to_date('22-02-2017', 'DD-MM-YYYY'), 81000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2012);

insert into angajati values (seq_med.nextval, 'Medic', 'Mihai', 'Alexandru', to_date('07-12-2019', 'DD-MM-YYYY'), 79000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2000);

insert into angajati values (seq_med.nextval, 'Medic', 'Marin', 'Ana-Maria', to_date('18-10-2018', 'DD-MM-YYYY'), 83000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2002);

insert into angajati values (seq_med.nextval, 'Medic', 'Cristea', 'Ion', to_date('05-08-2019', 'DD-MM-YYYY'), 75000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2000);

insert into angajati values (seq_med.nextval, 'Medic', 'Cretu', 'Maria', to_date('12-03-2020', 'DD-MM-YYYY'), 79000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2001);

insert into angajati values (seq_med.nextval, 'Medic', 'Popa', 'Darius', to_date('21-09-2020', 'DD-MM-YYYY'), 72000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2004);

insert into angajati values (seq_med.nextval, 'Medic', 'Laura', 'Elena', to_date('10-06-2021', 'DD-MM-YYYY'), 78000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2011);

insert into angajati values (seq_med.nextval, 'Medic', 'Matei', 'Alexandru', to_date('28-02-2022', 'DD-MM-YYYY'), 84000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2005);

insert into angajati values (seq_med.nextval, 'Medic', 'Mihai', 'Cristina', to_date('15-11-2022', 'DD-MM-YYYY'), 77000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2012);

insert into angajati values (seq_med.nextval, 'Medic', 'Radu', 'Stefan', to_date('03-08-2020', 'DD-MM-YYYY'), 82000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2006);

insert into angajati values (seq_med.nextval, 'Medic', 'Nastase', 'Adriana', to_date('19-04-2019', 'DD-MM-YYYY'), 79000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2007);

insert into angajati values (seq_med.nextval, 'Medic', 'Ilie', 'Mihai', to_date('07-01-2018', 'DD-MM-YYYY'), 83000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'specialist', 2002);

insert into angajati values (seq_med.nextval, 'Medic', 'Badea', 'Marius', to_date('07-10-2018', 'DD-MM-YYYY'), 60000);
insert into medici (id, tip, id_sectie) values (seq_med.currval, 'rezident', 2002);

-- INSERARE SOFERI --
create sequence seq_sof
start with 1000 
nocycle
nocache;

insert into angajati values (seq_sof.nextval, 'Sofer', 'Pop', 'George', to_date('22-10-2008', 'DD-MM-YYYY'), 30000);
insert into soferi(id, id_spital) values (seq_sof.currval, 200);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Ionescu', 'Marius', to_date('15-07-2011', 'DD-MM-YYYY'), 32000);
insert into soferi (id, id_spital) values (seq_sof.currval, 201);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Popescu', 'Alexandru', to_date('05-09-2014', 'DD-MM-YYYY'), 29000);
insert into soferi (id, id_spital) values (seq_sof.currval, 202);

insert into angajati values (seq_sof.nextval, 'Sofer', 'George', 'Andrei', to_date('28-02-2017', 'DD-MM-YYYY'), 31000);
insert into soferi (id, id_spital) values (seq_sof.currval, 205);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Tutu', 'Cosmin', to_date('23-06-2016', 'DD-MM-YYYY'), 35000);
insert into soferi (id, id_spital) values (seq_sof.currval, 200);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Ionescu', 'Maria', to_date('01-01-2010', 'DD-MM-YYYY'), 35000);
insert into soferi(id, id_spital) values (seq_sof.currval, 201);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Popescu', 'Alexandru', to_date('05-03-2012', 'DD-MM-YYYY'), 33000);
insert into soferi(id, id_spital) values (seq_sof.currval, 202);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Mihai', 'Ana', to_date('10-07-2014', 'DD-MM-YYYY'), 29000);
insert into soferi(id, id_spital) values (seq_sof.currval, 200);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Popa', 'Andrei', to_date('15-09-2016', 'DD-MM-YYYY'), 27000);
insert into soferi(id, id_spital) values (seq_sof.currval, 204);

insert into angajati values (seq_sof.nextval, 'Sofer', 'Costic', 'Cătălina', to_date('20-12-2018', 'DD-MM-YYYY'), 25000);
insert into soferi(id, id_spital) values (seq_sof.currval, 205);


-- INSERARE AMBULANTE --
create sequence seq_amb
start with 300
nocycle
nocache;

insert into ambulante values (seq_amb.nextval, 'AB123CD', 1, 200);
insert into ambulante values (seq_amb.nextval, 'EF456GH', 2, 201);
insert into ambulante values (seq_amb.nextval, 'IJ789KL', 1, 202);
insert into ambulante values (seq_amb.nextval, 'MN012OP', 2, 205);
insert into ambulante values (seq_amb.nextval, 'QR345ST', 1, 204);
insert into ambulante values (seq_amb.nextval, 'IF023CL', 1, 200);
insert into ambulante values (seq_amb.nextval, 'MF256GT', 2, 201);
insert into ambulante values (seq_amb.nextval, 'TM989KE', 1, 202);
insert into ambulante values (seq_amb.nextval, 'GJ612OI', 2, 205);
insert into ambulante values (seq_amb.nextval, 'B305STP', 1, 200);

--INSERARE SERVICII_AMBULANTA--
insert into servicii_amb values (1000, 100, 300, TO_DATE('01-05-2023', 'DD-MM-YYYY'), 'Accident rutier');
insert into servicii_amb values (1001, 101, 301, TO_DATE('02-06-2022', 'DD-MM-YYYY'), 'Probleme respiratorii');
insert into servicii_amb values (1002, 102, 302, TO_DATE('03-01-2023', 'DD-MM-YYYY'), 'Accident vascular cerebral');
insert into servicii_amb values (1003, 103, 303, TO_DATE('04-02-2020', 'DD-MM-YYYY'), 'Dureri abdominale severe');
insert into servicii_amb values (1004, 104, 304, TO_DATE('05-10-2020', 'DD-MM-YYYY'), 'Fractură osoasă');
insert into servicii_amb values (1005, 105, 305, TO_DATE('06-12-2021', 'DD-MM-YYYY'), 'Criză de astm');
insert into servicii_amb values (1006, 106, 306, TO_DATE('07-11-2022', 'DD-MM-YYYY'), 'Le?in');
insert into servicii_amb values (1007, 107, 307, TO_DATE('08-07-2023', 'DD-MM-YYYY'), 'Alergie severă');
insert into servicii_amb values (1008, 108, 308, TO_DATE('09-08-2023', 'DD-MM-YYYY'), 'Sângerare abundentă');
insert into servicii_amb values (1000, 110, 309, TO_DATE('10-04-2020', 'DD-MM-YYYY'), 'Arsură gravă');
insert into servicii_amb values (1000, 111, 300, TO_DATE('11-03-2021', 'DD-MM-YYYY'), 'Intoxica?ie alimentară');
insert into servicii_amb values (1001, 112, 301, TO_DATE('12-05-2022', 'DD-MM-YYYY'), 'Convulsii');
insert into servicii_amb values (1002, 113, 302, TO_DATE('13-06-2023', 'DD-MM-YYYY'), 'Accident rutier');
insert into servicii_amb values (1003, 114, 303, TO_DATE('14-10-2022', 'DD-MM-YYYY'), 'Intoxica?ie alimentară');
insert into servicii_amb values (1004, 115, 304, TO_DATE('15-05-2023', 'DD-MM-YYYY'), 'Le?in');
insert into servicii_amb values (1003, 114, 308, TO_DATE('14-09-2022', 'DD-MM-YYYY'), 'Convulsii');
insert into servicii_amb values (1004, 115, 313, TO_DATE('15-01-2023', 'DD-MM-YYYY'), 'Fractura osoasa');

--INSERARE MEDICAMENTE--
create sequence seq_mdm
start with 4000
nocycle
nocache;

insert into medicamente values (seq_mdm.nextval, 'Paracetamol', 'XYZ Company', to_date('06-01-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Ibuprofen', 'ABC Pharma', to_date('15-07-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Amoxicilină', 'DEF Pharma', to_date('28-02-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Omeprazol', 'GHI Corporation', to_date('11-10-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Aspirină', 'JKL Drugs', to_date('20-09-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Simvastatină', 'MNO Pharmaceuticals', to_date('04-05-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Metformină', 'PQR Labs', to_date('31-10-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Ventolin', 'STU Company', to_date('15-03-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Cetirizină', 'VWX Pharmaceuticals', to_date('08-10-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Loratadină', 'YZA Corporation', to_date('01-01-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Sertralină', 'BCD Drugs', to_date('12-05-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Losartan', 'EFG Pharmaceuticals', to_date('20-11-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Gabapentină', 'HIJ Labs', to_date('05-10-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Metoprolol', 'KLM Company', to_date('15-09-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Rosuvastatină', 'NOP Pharmaceuticals', to_date('15-02-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Ranitidină', 'QRS Drugs', to_date('10-01-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Clonazepam', 'STU Pharmaceuticals', to_date('20-03-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Levotiroxină', 'VWX Labs', to_date('08-05-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Furosemid', 'YZA Company', to_date('15-01-2024', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Ciprofloxacină', 'BCD Pharmaceuticals', to_date('20-12-2023', 'DD-MM-YYYY'));
insert into medicamente values (seq_mdm.nextval, 'Xanax', 'DPD Meds', to_date('10-08-2023', 'DD-MM-YYYY'));

--INSERARE DIAGNOSTICE--
create sequence seq_diag
start with 5025
nocycle
nocache;

insert into diagnostice values (seq_diag.nextval, 'Diabet', 'medicamentos');
insert into diagnostice values (seq_diag.nextval, 'Hipertensiune arterială', 'medicamentos' );
insert into diagnostice values (seq_diag.nextval, 'Gripă', 'medicamentos');
insert into diagnostice values (seq_diag.nextval, 'Insuficien?ă cardiacă', 'medicamentos');
insert into diagnostice values (seq_diag.nextval, 'Osteoporoză', 'exercitii fizice' );
insert into diagnostice values (seq_diag.nextval, 'Anemie','suplimente alimentare');
insert into diagnostice values (seq_diag.nextval, 'Migrenă','medicamentos, repaus' );
insert into diagnostice values (seq_diag.nextval, 'Ulcer gastric','medicamentos si dieta' );
insert into diagnostice values (seq_diag.nextval, 'Depresie','terapie si medicamentos');
insert into diagnostice values (seq_diag.nextval, 'Astm bron?ic', 'medicamentos, inhalatoare' );
insert into diagnostice values (seq_diag.nextval, 'Diabet', 'dieta');

--INSERARE RETETE--
insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5025, 4000, '5 mg', '7 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5025, 4011, '12 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5025, 4010, '9 mg', '4 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5026, 4001, '10 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5026, 4012, '12 mg', '10 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5027, 4002, '15 mg', '10 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5027, 4013, '8 mg', '21 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5028, 4003, '20 mg', '21 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5028, 4014, '15 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5026, 4004, '8 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5027, 4015, '10 mg', '7 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5025, 4002, '7 mg', '5 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5030, 4005, '12 mg', '7 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5030, 4016, '18 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5031, 4006, '18 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5031, 4017, '25 mg', '10 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5032, 4007, '25 mg', '10 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5032, 4018, '15 mg', '21 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5030, 4008, '15 mg', '21 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5030, 4019, '12 mg', '14 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5031, 4020, '6 mg', '8 zile');

insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5032, 4015, '2 mg', '7 zile');


insert into retete (id_diagnostic, id_medicament, doza, durata)
values (5034, 4009, '10 mg', '14 zile');

--INSERARE CONSULATATII--
create sequence seq_cons
start with 1
nocycle
nocache;

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1400, 150, 5025, to_date('18.10.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1401, 151, 5026, to_date('19.08.2020', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1402, 152, 5027, to_date('20.06.2021', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1403, 153, 5028, to_date('21.04.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1404, 154, 5029, to_date('22.02.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1405, 155, 5030, to_date('23.10.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1406, 156, 5031, to_date('24.10.2019', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1407, 157, 5032, to_date('25.11.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1408, 158, 5033, to_date('26.09.2019', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1409, 159, 5034, to_date('27.10.2018', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1410, 160, 5035, to_date('22.12.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1411, 161, 5025, to_date('29.10.2020', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1412, 162, 5026, to_date('10.05.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1413, 163, 5027, to_date('31.10.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1414, 164, 5028, to_date('01.11.2010', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1415, 165, 5029, to_date('02.11.2013', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1416, 166, 5030, to_date('03.11.2015', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1417, 167, 5031, to_date('04.01.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1418, 168, 5032, to_date('05.11.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1419, 169, 5033, to_date('06.11.2020', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1420, 170, 5034, to_date('07.11.2021', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1400, 150, 5035, to_date('08.10.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1401, 151, 5025, to_date('09.12.2020', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1402, 153, 5026, to_date('10.11.2021', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1403, 154, 5027, to_date('11.07.2021', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1404, 151, 5028, to_date('12.01.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1405, 154, 5029, to_date('13.03.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1406, 160, 5030, to_date('14.04.2023', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1407, 160, 5031, to_date('15.10.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1408, 160, 5032, to_date('16.12.2020', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1400, 100, 5025, to_date('30.06.2022', 'DD.MM.YYYY'));

insert into consultatii (id, id_medic, id_pacient, id_diagnostic, data_examinarii)
values (seq_cons.nextval, 1408, 101, 5027, to_date('30.06.2022', 'DD.MM.YYYY'));

--INSERARE FACTURI--
create sequence seq_fac
start with 7000
nocycle
nocache;

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 200, 'cash', 1);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 150, 'card', 2);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 300, 'cash', 3);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 180, 'card', 4);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 250, 'cash', 5);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 220, 'card', 6);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 280, 'cash', 7);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 190, 'card', 8);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 320, 'cash', 9);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 170, 'card', 10);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 220, 'cash', 11);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 300, 'card', 12);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 190, 'cash', 13);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 260, 'card', 14);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 240, 'cash', 15);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 180, 'card', 16);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 290, 'cash', 17);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 210, 'card', 18);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 280, 'cash', 19);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 230, 'card', 20);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 290, 'cash', 21);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 220, 'card', 22);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 310, 'cash', 23);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 200, 'card', 24);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 270, 'cash', 25);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 190, 'card', 26);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 280, 'cash', 27);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 230, 'card', 28);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 320, 'cash', 29);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 250, 'card', 30);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 150, 'cash', 31);

insert into facturi (id, suma, mod_plata, id_consultatie)
values (seq_fac.nextval, 50, 'cash', 32);
