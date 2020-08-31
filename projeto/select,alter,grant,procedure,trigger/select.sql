-- 1 seleciona pessoa  qual tipo de grupo  que ela pertence (cliente,fornecedor,revendedor...)e dados dela
SELECT a.nome,tp.tipo_contato,tp.ddd,tp.fone,e.endereco,b.nome as bairro,m.nome as cidade,es.nome as estado,g.nome as GRUPO FROM pessoa a  JOIN endereco e 
ON e.id = a.id_endereco
JOIN bairro b
ON b.id= e.id_bairro
JOIN municipio m
ON m.id = b.id_municipio
JOIN estado es
ON es.id=m.id_estado
JOIN pessoa_grupo pg
ON a.id= pg.id_pessoa
JOIN grupo g
ON g.id = pg.id_grupo
JOIN contato cont
ON a.id = cont.id_pessoa
JOIN tipo_contato tp
ON tp.id = cont.id_tipo_contato
-- WHERE g.nome in('Cliente','Fornecedor','Revendedor','Colaborador')
ORDER BY a.nome;


-- selecione as pessoas que não são clientes
SELECT a.nome,g.nome as GRUPO FROM pessoa_grupo pg JOIN pessoa a 
ON a.id = pg.id_pessoa
JOIN grupo g
ON g.id = pg.id_grupo
WHERE g.nome NOT IN('cliente');


-- 3 selecione o nome do cliente , produto que ele comprou a quantidade,preco  da unidade do produto  a forma de pagamento e total da conta
SELECT a.nome as cliente, p.descricao as produto,f.nome as fabricante,i.qtd as quantidade,format(v.valor_venda,2) as preco_unidade,fp.ds_forma_pag as pagamento,format(i.qtd *valor_venda,2) as total_conta FROM  venda v 
join pessoa a
ON a.id = v.id_cliente
JOIN forma_pagamento fp
ON fp.id =v.id_forma_pag
JOIN item_venda i
ON v.id = i.id_venda
JOIN produto p
ON p.id = i.id_produto
JOIN fabricante f
ON f.id =p.id_fabricante
ORDER BY a.nome;

 -- 4  selecione o nome do cliente e apresenta o total da conta por itens(quantidade) ou seja incluindo todos os produtos 
SELECT a.nome as cliente,format(sum(i.qtd *valor_venda),2)  as total_conta FROM  venda v 
join pessoa a
ON a.id = v.id_cliente
JOIN forma_pagamento fp
ON fp.id =v.id_forma_pag
JOIN item_venda i
ON v.id = i.id_venda
JOIN produto p
ON p.id = i.id_produto
JOIN fabricante f
ON f.id =p.id_fabricante
GROUP BY a.nome;

-- 5 informe o status da  compra do cliente 
SELECT a.nome as cliente,st.ds_status as Atendimento_do_pedido,p.descricao as produto,i.qtd as quantidade FROM  venda v join pessoa a
ON a.id = v.id_cliente
JOIN rl_status_venda rl
ON v.id = rl.id_venda
JOIN status_venda st
ON st.id = rl.id_status_venda
JOIN item_venda i
ON v.id = i.id_venda
JOIN produto p
ON p.id = i.id_produto
ORDER BY a.nome;

-- 6 Selecionar todos os clientes que não fizeram pedidos	
SELECT ifnull(a.nome, '')  as cliente  FROM venda v JOIN pessoa a
ON a.id = v.id_cliente
JOIN item_venda i
ON v.id = i.id_venda
WHERE v.id_cliente IS NULL
-- WHERE v.id_cliente IS not null
ORDER BY a.nome;


/*7  selecione os cliente que tiveram  a conta paga e saldo pago ou seja a conta essa verificando (status da compra) é o saldo exato pq conta pode altera de status a qualquer momento aqui é saldo exato da compra,
diferente do select anteriores */
CREATE OR REPLACE VIEW uvw_saldo_pessoa as SELECT date_format(dt_emissao, '%d/%m/%Y') as dt_emissao,date_format(dt_vencimento,'%d/%m/%Y') as dt_vencimento, format(c.valor,2) as valor, a.nome as cliente FROM conta c
JOIN pessoa a 
ON a.id = c.id_cliente
WHERE c.paga = 's' or c.paga ='n'
order by a.nome;

-- chamada da view
select * from uvw_saldo_pessoa; 

-- 8 seleciona os  clientes onde a compra foi cancelada
SELECT date_format(dt_emissao, '%d/%m/%Y') as dt_emissao,date_format(dt_vencimento,'%d/%m/%Y') as dt_vencimento, format(c.valor,2) as valor, a.nome as cliente FROM conta c
JOIN pessoa a 
ON a.id = c.id_cliente
WHERE c.paga = 's'; 
 
 -- 9  Faça uma função que retorne o total de venda;
DELIMITER $$
DROP FUNCTION IF EXISTS fn_rt_total_vendas $$
CREATE FUNCTION  fn_rt_total_vendas () RETURNS FLOAT
DETERMINISTIC
	BEGIN 
    DECLARE total FLOAT;
    SELECT MAX(preco) INTO total FROM item_venda;
    RETURN total;
END $$
DELIMITER ;    

-- chamada function
SELECT format(fn_rt_total_vendas(),2) as total_vendas;

 -- 10  Selecionar a quantidade de pedidos por cliente, onde a conta foi aprovada(paga)
 SELECT a.nome as cliente,count(i.id_produto) as qtd_pedido_por_cliente,p.descricao FROM venda v   JOIN pessoa a
 ON a.id = v.id_cliente
 JOIN item_venda i
 ON v.id = i.id_venda
 JOIN produto p
 ON p.id = i.id_produto
 JOIN conta c
 ON a.id = c.id_cliente
WHERE c.paga  = 's'
GROUP by a.nome
ORDER BY a.nome;

--  procedure para add usuário
delimiter $$
	drop procedure if exists sp_add_user $$
    create procedure sp_add_user (IN p_nome varchar(45) ,IN  p_senha varchar(200))
    begin
		declare nome_host varchar(15) default '@\'localhost\'';
        set p_nome = concat('\'',TRIM(p_nome), '\'', nome_host);
        set p_senha = concat('\'', (p_senha), '\'');
        set @sql = concat('CREATE USER ' ,p_nome, ' IDENTIFIED BY ' , p_senha);
        prepare sql_add from @sql; -- prepara comando sql
        execute sql_add;
        deallocate prepare sql_add;
        flush privileges;
   end $$;     
delimiter ;	

CALL sp_add_user ('camila',12345);
CALL sp_add_user ('estagiario',12345);

-- criando regras ADM_DB
create role 'senior', 'pleno', 'junior'; -- múltiplas regras

GRANT ALL ON controle_vendas.* TO 'senior';
GRANT CREATE,INSERT,SELECT, UPDATE, DELETE,ALTER,DROP ON controle_vendas.* TO 'pleno';
GRANT SELECT ON controle_vendas.* TO 'junior';


-- aplicando regras para users
grant 'senior' to 'camila'@'localhost';
grant  'junior' to 'estagiario'@'localhost';
grant  'pleno' to 'aluno'@'localhost';


-- exibir a regras concedidas
show grants for 'camila'@'localhost' using senior;
show grants for 'estagiario'@'localhost' using junior;

 -- ativando a regra para o user
select CURRENT_ROLE(); -- exibir todas as regras
SET DEFAULT ROLE ALL TO 'camila'@'localhost';
SET DEFAULT ROLE ALL TO 'estagiario'@'localhost';
SET DEFAULT ROLE ALL TO 'aluno'@'localhost';
set role none ; -- limpar todas as regras 


-- Revogando regas ou Privilégios da regras

-- revogando todas as regas 
revoke 'senior' FROM 'camila'@'localhost';
revoke 'junior' FROM 'estagiario'@'localhost';

-- regovando regras por (opção) ex como a regra do pleno tem (CREATE,INSERT,SELECT, UPDATE, DELETE,ALTER,DROP) 
REVOKE select ON controle_vendas.* FROM 'pleno';  -- revogando só select ou seja todo user que tiver a regra pleno não vai ter mais opção select


-- deletar user
drop user 'TESTE'@'localhost';
DROP USER  camila@'%'; -- excluir  user de qualquer host
drop role senior; -- excluir regras






 
 
