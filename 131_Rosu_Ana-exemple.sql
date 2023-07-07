--12

--1. Spitalele din afara Bucurestiului care au un număr de secții mai mare decât media numărului de secții al spitalelor din Bucuresti.

-- Cererea utilizeaza grupări de date cu subcereri nesincronizate in care intervin cel putin 3 tabele, funcții
-- grup, filtrare la nivel de grupuri, 2 functii pe siruri de caractere, subcerere nesincronizata în clauza FROM

select s.id, s.nume, a.judet, count(sec.id) numar_sectii
from spitale s
join adrese a on a.id = s.id_adresa
join sectii sec on sec.id_spital = s.id
where lower(a.judet) != 'bucuresti'
group by s.id, s.nume, a.judet
having count(sec.id) > (select avg(numar_sectii)
                        from (
                            select s.id, count(sec.id) numar_sectii
                            from spitale s
                            join adrese a on a.id = s.id_adresa
                            join sectii sec on sec.id_spital = s.id
                            where initcap(a.judet) = 'Bucuresti'
                            group by s.id )
);

--2. Să se afișeze numele, prenumele, vârsta pacienților cu număr maxim de consultații și diagnosticele asociate lui/lor.

--- Cererea utilizeaza un 1 bloc de cerere (clauza WITH), subcerere nesincronizata în clauza FROM, grupari de date,
-- filtrare la nivel de grupuri, functii grup

with pac as (
    select p.id pac_id
    from pacienti p
    join consultatii c on c.id_pacient = p.id
    group by p.id
    having count(c.id_pacient) = ( select max(nr_consultatii) nr_max_cons
                                    from (
                                            select count(id_pacient) nr_consultatii
                                            from consultatii
                                            group by id_pacient )
                                  )
)
select p.id, p.nume, p.prenume, extract(year from sysdate) - extract(year from p.data_nasterii) varsta, d.nume
from pacienti p
join pac on pac.pac_id = p.id
join consultatii c on c.id_pacient = p.id
join diagnostice d on c.id_diagnostic = d.id;

--3.  Să se afișeze, pentru fiecare diagnostic în parte, numărul total de consultații și încasările provenite din plata cu cardul.
--Rezultatele sunt afișate în ordine descrescătoare a numărului de consultații, respectiv a încasărilor.

-- Cererea utilizeaza functiile NVL și DECODE, functii grup, grupari de date, functie pe siruri de caractere

select d.nume, count(c.id) nr_consultatii,
sum(nvl(decode(upper(f.mod_plata), 'CARD', f.suma), 0)) suma_plata_card
from diagnostice d
join consultatii c on d.id = c.id_diagnostic
join facturi f on c.id = f.id_consultatie
group by d.nume
order by nr_consultatii desc, suma_plata_card desc;

--4.Sa se afiseze numele si nivelul de experienta al medicilor de pe sectia de neurologie al spitalelor care se afla in orasul Suceava.
--Se considera medic avansat cel cu experienta de lucru sub 5 ani si medic experimentat cel cu vechime de peste 5 ani.

-- Cererea utilizeaza expresia CASE, functie pe date calendaristice, functii pe siruri de caractere

select a.nume || ' ' || a.prenume nume_medic, sec.nume nume_sectie,
    case
        when months_between(sysdate,a.data_angajarii) < 60 then 'Avansat'
        when months_between(sysdate,a.data_angajarii) >= 60 then 'Experimentat'
    end categorie_medic, sp.nume nume_spital
from  medici m
join angajati a on a.id = m.id
join sectii sec on sec.id = m.id_sectie
join spitale sp on sp.id = sec.id_spital
join adrese ad on ad.id = sp.id_adresa
where lower(sec.nume) = 'cardiologie'
and lower(ad.oras) = 'suceava';

--5. Numarul consultatiilor de la sectia de ortopedie in cadrul carora 
--pacientului i s-au prescris medicamente care expira in urmatoarele 3 luni 

-- Cererea utilizeaza subcereri sincronizate în care intervin 5 tabele, functie pe data calendaristica,
--functii pe siruri de caractere, functii grup

select count(c.id) nr_cons
from consultatii c
join medici med on med.id = c.id_medic
join sectii sec on med.id_sectie = sec.id
where c.id_pacient in ( select p.id
                        from pacienti p
                        join consultatii cons on cons.id_pacient = p.id
                        join diagnostice diag on diag.id = cons.id_diagnostic
                        join retete ret on ret.id_diagnostic = diag.id
                        join medicamente m on ret.id_medicament = m.id
                        where p.id = c.id_pacient
                        and m.data_expirarii between sysdate and add_months(sysdate, 3)
                        )
and lower(sec.nume) = 'ortopedie';


--13
--ACTUALIZARI DATE

--Să se actualizeze adresa pacienților care au avut consultații după data de 1 mai 2023 cu adresa Sibiu, Strada Vasile Alecsandri, nr 8.
update pacienti
set id_adresa = (
    select id
    from adrese
    where lower(oras) = 'sibiu' and lower(strada) = 'strada vasile alecsandri' and numar = 8
)
where id in (
    select id_pacient
    from consultatii
    where data_examinarii >= to_date('01-05-2023', 'DD-MM-YYYY')
);

--Să se actualizeze compania producătoare a medicamentelor utilizate in tratamentul diagnosticului 'Gripă'

update medicamente
set companie = 'Gripovit'
where id in (
    select r.id_medicament
    from retete r
    join diagnostice d on r.id_diagnostic = d.id
    where lower(d.nume) like 'gripă'
);

--STERGERE DATE 
--Sa se stearga toate sectiile in care nu lucreaza niciun medic.              
delete from sectii
where id not in (
    select distinct id_sectie
    from medici 
);

--15

-- ANALIZA TOP-N
--Sa se afiseze top 2 spitale cu cele mai multe transporturi cu ambulanta.
with aux as 
     (select a.id_spital, count(a.id_spital) nr_serv
      from servicii_amb sa 
      join ambulante a on a.id = sa.id_ambulanta
      group by a.id_spital
)
select *
from (
  select s.id, s.nume, aux.nr_serv
  from spitale s
  join aux on s.id = aux.id_spital
  order by aux.nr_serv desc
)
where rownum <= 2;

--OPERATIA DIVISION

--Sa se afiseze codurile si numele medicamentelor care au fost prescrise in toate consultatiile care au avut loc in ultima zi din iunie a anului precedent

--varianta 1 
-- afisam medicamentele pentru care nu există nicio consultatie din data ceruta care
--să nu aibă asociată un rând în tabela "retete" pentru medicamentul curent

select m.id, m.nume
from medicamente m
where not exists (
    select *
    from consultatii c
    where c.data_examinarii = to_date('30.06.' || to_char(extract(year from sysdate) - 1), 'DD.MM.YYYY')
    and not exists (
          select *
          from retete r
          where r.id_diagnostic = c.id_diagnostic
          and r.id_medicament = m.id )
); 


--varianta 2
select m.id, m.nume
from medicamente m
where m.id in (
    select r.id_medicament
    from retete r
    join diagnostice d on r.id_diagnostic = d.id
    join consultatii c on c.id_diagnostic = d.id
    where c.data_examinarii = to_date('30.06.' || to_char(extract(year from sysdate) - 1), 'DD.MM.YYYY')
    group by r.id_medicament
    having count(distinct c.id) = (
        select count(*)
        from consultatii
        where data_examinarii = to_date('30.06.' || to_char(extract(year from sysdate) - 1), 'DD.MM.YYYY')
    )
);

-- OUTER JOIN PE 4 TABELE

--Sa se afiseze toti pacientii, inclusiv cei pentru care nu este inregistrata nicio consultatie, 
--iar pentru cei care au inregistrate consultatii, sa se afiseze data examinarii si id-ul medicului, precum
--si diagnosticul asociat consultatiilor, retetele pentru medicamentele incluse in tratament, in cazul in care acesta este
--de tip medicamentos, iar pentru cei care nu au tratament de tip medicamentos sa se afiseze null in toate campurile.
--Sa se afiseze rezultatele crescator in functie de data la care a avut loc consultatia
--de id-ul pacientului si de tipul tratamentului.

select p.id, p.nume || ' ' || p.prenume nume_pacient, c.data_examinarii, c.id_medic,
d.nume nume_diagnostic, d.tip_tratament, r.id_medicament,m.nume nume_medicament, r.doza, r.durata
from pacienti p 
left join consultatii c on p.id = c.id_pacient
left join diagnostice d on d.id = c.id_diagnostic
left join retete r on r.id_diagnostic = d.id
left join medicamente m on m.id = r.id_medicament
order by c.data_examinarii, p.id, d.tip_tratament;
