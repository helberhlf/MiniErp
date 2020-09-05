-- substring vai extrai um parte da sua string (coluna, posicao, qtd de caracterese)
select subtstring (nome,1,8) from estado;

-- alteração na table estado 
alter table estado add column id_regiao int not null;
alter table estado add primary key (id);
update estado set id_regiao = substring(regiao,8,1);
alter table estado drop column regiao;

select * from estado;


 -- alteração na table municipio
alter table municipio add column id_estado int not null; 
alter table municipio add primary key (id);
update municipio set id_estado = substring(id,1,2);
alter table municipio drop column  microrregiao;

select * from municipio;


select  m.id, m.nome as cidade,e.nome as estado from municipio m join estado e
on e.id = m.id_estado
where e.nome = 'Distrito Federal';


