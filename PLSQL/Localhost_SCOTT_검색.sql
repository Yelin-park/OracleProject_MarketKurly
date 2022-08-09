
--1. ��ǰ Ű����� �˻� ��� ���� ���ν��� ����
create or replace procedure mkp_p_search 
 ( 
    pp_name product.p_name%type -- ��ǰ�� �Ű�����
 )
 is
 vproduct product%rowtype;
 mk_e_product_search exception; -- ����ó��
  cursor p_searck_cursor is(
        select P_CODE, P_NAME, P_PRICE, P_DISCOUNT, P_DETAIL,P_COLD_TYPE, V_CODE, CTGR_CODE, B_CODE, P_RDATE
        from product
        where regexp_like(P_NAME, pp_name) 
  );
 begin
 
            open p_searck_cursor;
                loop   
                fetch p_searck_cursor into vproduct.P_CODE, vproduct.P_NAME , vproduct.P_PRICE , vproduct.P_DISCOUNT , vproduct.P_DETAIL,
                      vproduct.P_COLD_TYPE, vproduct.V_code, vproduct.CTGR_CODE , vproduct.B_CODE  ,vproduct.P_RDATE ;
        
                        if vproduct.p_name is null then
                        raise mk_e_product_search;
                        end if;
                        
                 exit when p_searck_cursor%notfound or p_searck_cursor%rowcount>=60;     
                
                        dbms_output.put_line( vproduct.P_NAME || ', ' || vproduct.P_PRICE || '��');
                        
                end loop;
                
                close p_searck_cursor;
 exception
        when mk_e_product_search then
        dbms_output.put_line( ' ��ǰ�� ã�� �� �����ϴ�. ');
 end;
 
 --��ǰ Ű���� �˻� ���� ���ν��� �׽�Ʈ Ȯ��
 exec mkp_p_search('�����');
 --����ó�� Ȯ��
 exec mkp_p_search('������');
 
 
 
 
 --2. ī�װ��� �˻� �������ν��� ����
 create or replace procedure mkp_cgr_search -- ���� ���ν��� ( in ,out ,inout )
 ( 
    pctgr_name category.ctgr_name%type --ī�װ��̸��� �Ű������� ����
 )
 is
         vproduct product%rowtype;
         vctgr_name category.ctgr_name%type;
            cursor ctgr_searck_cursor is(
                select p_name, p_price, ctgr_name 
                from product p join category c on p.ctgr_code = c.ctgr_code
                where regexp_like(ctgr_name, pctgr_name )   
        );
    mk_e_ctgr_search    exception; 
 begin    
        open ctgr_searck_cursor;          
                loop 
                fetch ctgr_searck_cursor into vproduct.p_name, vproduct.p_price, vctgr_name;
                            
                        if vctgr_name is null then 
                        raise mk_e_ctgr_search;
                        end if;
                    exit when ctgr_searck_cursor%notfound; -- or ctgr_searck_cursor%rowcount>=60
                    dbms_output.put_line( vproduct.P_NAME || ', ' || vproduct.P_PRICE || '��');
                end loop;   
                
        close ctgr_searck_cursor;
               
    exception
        when mk_e_ctgr_search then
        dbms_output.put_line( '��ǰ�� ã�� �� �����ϴ�.' );
 end;
 
-- ī�װ� ��ȸ �������ν��� �׽�Ʈ
exec mkp_cgr_search('����');
--ī�װ� ��ȸ ���ܹ߻� �׽�Ʈ.
exec mkp_cgr_search('������'); 
 
select * from product;
select * from category;


-- 3-1 �̻�ǰ �˻� �������ν����� ���� ��
create or replace view v_p_newlist
as  select p_name , p_price
    from product
    order by p_rdate desc
with read only;   

-- 3-2. �Ż�ǰ �˻� �������ν��� ����.
create or replace procedure mkp_newproduct
is
    vp_name product.p_name%type;
    vp_price product.p_price%type;
    cursor c_mk_newproduct is ( 
        select p_name,p_price       
        from v_p_newlist        
 );
 mk_e_search exception;
begin
    open c_mk_newproduct;
    loop
    fetch c_mk_newproduct into vp_name, vp_price;
         
         if vp_name is null then
          raise mk_e_search;
        end if;
         exit when c_mk_newproduct%notfound or c_mk_newproduct%rowcount >= 60;
          dbms_output.put_line( vp_name || ',' || vp_price || rpad( '��' ,5 , ' ' ) );

    end loop;
    close c_mk_newproduct;
exception
    when mk_e_search then
        dbms_output.put_line( '��ǰ�� ã�� �� �����ϴ�.' );
end;
-- �Ż�ǰ �˻� �������ν��� �׽�Ʈ
exec mkp_newproduct;

--4-1. ����Ʈ ��ǰ �˻� ���� ��
    create or replace view v_p_total_sales
    as 
    select p_name, p_price
    from product
    order by total_sales desc -- ���Ǹŷ����� ����
    with read only;
--4-2. ����Ʈ ��ǰ �˻� ���� ���ν��� 
create or replace procedure mkp_bescproduct
    -- () �Ű����� ����
    is 
    vp_name product.p_name%type;
    vp_price product.p_price%type;
        cursor c_mk_bestproduct is(
            select p_name , p_price
            from v_p_total_sales -- �Ǹ� ���̵� ������ ���ĵ� �並 cursor�� ����.
        );
    begin
        open c_mk_bestproduct;
        loop
        fetch c_mk_bestproduct into vp_name, vp_price;
            exit when c_mk_bestproduct%notfound or c_mk_bestproduct%rowcount >= 60;
            dbms_output.put_line( vp_name || ',' || vp_price || rpad( '��' ,5 , ' ' ) );
        end loop;
        close c_mk_bestproduct;
    --exception
    end;

-- ����Ʈ��ǰ ��� �׽�Ʈ
exec mkp_bescproduct;


-- 5-1. ���� �� 

-- 5-2. �� ī�װ��� ��ϼ� ��ȸ ���ν��� ����
create or replace procedure mkp_child_ctgrNEW
        ( 
         pctgr_name category.ctgr_name%type -- ī�װ����� �Է¹���
        )
        is 
         vdsql varchar2(2000);
         vcursor SYS_REFCURSOR;
         vrow v_ctgr_NEW%rowtype;
         mk_e_search exception;
        begin 
         vdsql := 'select * ';
         vdsql := vdsql || 'from v_ctgr_NEW ';
         vdsql := vdsql || 'where regexp_like(ctgr_name , :ctgr_name)';
          open vcursor for vdsql USING pctgr_name; 
          loop 
            fetch vcursor into vrow;
            if vrow.p_name is null then
             raise mk_e_search;
            end if;
            exit when vcursor%notfound;
            DBMS_OUTPUT.PUT_LINE( vrow.p_name||' ,'|| vrow.p_price );
          end loop;
            close vcursor;
        exception 
         when mk_e_search then
          DBMS_OUTPUT.PUT_LINE('ī�װ��� �ٽ� �Է����ּ���.');
        end;
-- ��� �׽�Ʈ
        exec mkp_child_ctgrNEW('����');
-- ���� ��Ȳ �׽�Ʈ
        exec mkp_child_ctgrNEW('����');
        
        
--5-1. �� ����
create or replace view v_ctgr_Wnew
as
    select p_name, p_price, ctgr_top , c.ctgr_name, p_rdate
    from category c left join product p on p.ctgr_code = c.ctgr_code 
    where p_name is not null
    order by ctgr_top asc,p_rdate desc;
--5-2.        >��ü ī�װ��� ��ϼ�<

-- ��ü ī�װ��� ��ϼ� ��ȸ ���� ���νü� ����
        create or replace procedure p_wcategory_rank
        ( -- ��üī�װ� �ڵ� �Է¹��� ex A1
         pctgr_top category.ctgr_top%type
        )
        is 
            vp_name product.p_name%type;
            vp_price product.p_price%type;
        cursor c_mk_Wcategory is (
               select p_name , p_price
               from v_ctgr_Wnew
               where ctgr_top = pctgr_top   
        );
        mk_e_search exception;
        begin
            open c_mk_Wcategory;
            loop
                fetch c_mk_Wcategory into vp_name , vp_price;
                if vp_name is null then
                raise mk_e_search;
                end if;
                exit when c_mk_Wcategory%notfound;
                dbms_output.put_line( vp_name || ',' || vp_price );
            end loop;
            close c_mk_Wcategory;
    
        exception 
            when mk_e_search then
             dbms_output.put_line('�˻� Ű���� �ٽ� �Է����ּ���.');
        end;
-- ��ü ī�װ��� ��ϼ� ��ȸ �׽�Ʈ �� Ȯ��      
        exec p_wcategory_rank('A1');
-- ��ü ī�װ��� ��ϼ� ���� �߻�.        
        exec p_wcategory_rank('A10');

        
        --6-1. ��
        create or replace view v_ctgr_best
        as
        select p_name , p_price , TOTAL_SALES , ctgr_name
        from product p join category c on p.ctgr_code = c.ctgr_code
        order by TOTAL_SALES desc;
        --6-2.        >�� ī�װ��� �α��<
         create or replace procedure mkp_child_ctgrBEST
        ( -- ī�װ��� �Ķ���ͷ� ������ �԰��� ���� ex(����, ����, ���Ʈ)
         pctgr_name category.ctgr_name%type
        )
        is -- �����
         vdsql varchar2(2000);
         vcursor SYS_REFCURSOR;
         vrow v_ctgr_BEST%rowtype;
         mk_e_search exception;
        begin -- �����
         vdsql := 'select * ';
         vdsql := vdsql || 'from v_ctgr_best ';
         vdsql := vdsql || 'where regexp_like(ctgr_name , :ctgr_name)';  --ctgr_name = :ctgr_name 
          open vcursor for vdsql USING pctgr_name; 
          loop 
            fetch vcursor into vrow;
            if vrow.p_name is null then
            raise mk_e_search;
            end if;
            exit when vcursor%notfound;
            DBMS_OUTPUT.PUT_LINE( vrow.p_name||' ,'|| vrow.p_price );
          end loop;
            close vcursor;
        exception
            when mk_e_search then
            DBMS_OUTPUT.PUT_LINE('Ű���� �ٽ� �Է��� �ּ���.');
        end;
-- �� ī�װ��� �α�� �׽�Ʈ
    exec mkp_child_ctgrBEST('����');
-- �� ī�װ��� �α�� ���� �߻�
    exec mkp_child_ctgrBEST('����');



--     7-1.  ��
    create or replace view v_ctgr_Wbest
    as
    select p_name, p_price, ctgr_top , c.ctgr_name, total_sales
    from category c left join product p on p.ctgr_code = c.ctgr_code 
    where p_name is not null
    order by ctgr_top asc, total_sales desc ;      
        
--     7-2.        >��ü ī�װ��� �α��<
create or replace procedure p_wcategory_rank
        ( -- ��üī�װ� �ڵ� �Է¹��� ex A1
         pctgr_top category.ctgr_top%type
        )
        is 
            vp_name product.p_name%type;
            vp_price product.p_price%type;
        cursor c_mk_categorybest is (
               select p_name , p_price
               from v_ctgr_Wbest
               where ctgr_top = pctgr_top   
        );
        mk_e_search exception;
        begin
            open c_mk_categorybest;
            loop
                fetch c_mk_categorybest into vp_name , vp_price;
                if vp_name is null then
                raise mk_e_search;
                end if;
                exit when c_mk_categorybest%notfound;
                dbms_output.put_line( vp_name || ',' || vp_price );
            end loop;
            close c_mk_categorybest;
        exception   
            when mk_e_search then
             dbms_output.put_line( 'Ű���� �ٽ� �Է��ϼ���.' );
        end;        
-- ��ü ī�װ��� �α�� �׽�Ʈ
exec p_wcategory_rank('H1');
-- ��ü ī�װ��� �α�� ���� �׽�Ʈ
exec p_wcategory_rank('H10');

