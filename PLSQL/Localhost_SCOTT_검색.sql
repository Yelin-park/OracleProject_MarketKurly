
--1. 상품 키워드로 검색 기능 저장 프로시저 생성
create or replace procedure mkp_p_search 
 ( 
    pp_name product.p_name%type -- 상품명 매개변수
 )
 is
 vproduct product%rowtype;
 mk_e_product_search exception; -- 예외처리
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
                
                        dbms_output.put_line( vproduct.P_NAME || ', ' || vproduct.P_PRICE || '원');
                        
                end loop;
                
                close p_searck_cursor;
 exception
        when mk_e_product_search then
        dbms_output.put_line( ' 상품을 찾을 수 없습니다. ');
 end;
 
 --상품 키워드 검색 저장 프로시저 테스트 확인
 exec mkp_p_search('유기농');
 --예외처리 확인
 exec mkp_p_search('강아지');
 
 
 
 
 --2. 카테고리로 검색 저장프로시저 생성
 create or replace procedure mkp_cgr_search -- 저장 프로시저 ( in ,out ,inout )
 ( 
    pctgr_name category.ctgr_name%type --카테고리이름을 매개변수로 받음
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
                    dbms_output.put_line( vproduct.P_NAME || ', ' || vproduct.P_PRICE || '원');
                end loop;   
                
        close ctgr_searck_cursor;
               
    exception
        when mk_e_ctgr_search then
        dbms_output.put_line( '상품을 찾을 수 없습니다.' );
 end;
 
-- 카테고리 조회 저장프로시저 테스트
exec mkp_cgr_search('우유');
--카테고리 조회 예외발생 테스트.
exec mkp_cgr_search('강아지'); 
 
select * from product;
select * from category;


-- 3-1 싱상품 검색 저장프로시저에 사용된 뷰
create or replace view v_p_newlist
as  select p_name , p_price
    from product
    order by p_rdate desc
with read only;   

-- 3-2. 신상품 검색 저장프로시저 생성.
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
          dbms_output.put_line( vp_name || ',' || vp_price || rpad( '원' ,5 , ' ' ) );

    end loop;
    close c_mk_newproduct;
exception
    when mk_e_search then
        dbms_output.put_line( '상품을 찾을 수 없습니다.' );
end;
-- 신상품 검색 저장프로시저 테스트
exec mkp_newproduct;

--4-1. 베스트 상품 검색 사용된 뷰
    create or replace view v_p_total_sales
    as 
    select p_name, p_price
    from product
    order by total_sales desc -- 총판매량수로 정렬
    with read only;
--4-2. 베스트 상품 검색 저장 프로시저 
create or replace procedure mkp_bescproduct
    -- () 매개변수 없음
    is 
    vp_name product.p_name%type;
    vp_price product.p_price%type;
        cursor c_mk_bestproduct is(
            select p_name , p_price
            from v_p_total_sales -- 판매 많이된 순으로 정렬된 뷰를 cursor로 받음.
        );
    begin
        open c_mk_bestproduct;
        loop
        fetch c_mk_bestproduct into vp_name, vp_price;
            exit when c_mk_bestproduct%notfound or c_mk_bestproduct%rowcount >= 60;
            dbms_output.put_line( vp_name || ',' || vp_price || rpad( '원' ,5 , ' ' ) );
        end loop;
        close c_mk_bestproduct;
    --exception
    end;

-- 베스트상품 출력 테스트
exec mkp_bescproduct;


-- 5-1. 사용된 뷰 

-- 5-2. 상세 카테고리별 등록순 조회 프로시저 생성
create or replace procedure mkp_child_ctgrNEW
        ( 
         pctgr_name category.ctgr_name%type -- 카테고리명을 입력받음
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
          DBMS_OUTPUT.PUT_LINE('카테고리르 다시 입력해주세요.');
        end;
-- 결과 테스트
        exec mkp_child_ctgrNEW('우유');
-- 예외 상황 테스트
        exec mkp_child_ctgrNEW('샛별');
        
        
--5-1. 뷰 생성
create or replace view v_ctgr_Wnew
as
    select p_name, p_price, ctgr_top , c.ctgr_name, p_rdate
    from category c left join product p on p.ctgr_code = c.ctgr_code 
    where p_name is not null
    order by ctgr_top asc,p_rdate desc;
--5-2.        >전체 카테고리별 등록순<

-- 전체 카테고리별 등록순 조회 저장 프로시서 생성
        create or replace procedure p_wcategory_rank
        ( -- 전체카테고리 코드 입력받음 ex A1
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
             dbms_output.put_line('검색 키워드 다시 입력해주세요.');
        end;
-- 전체 카테고리별 등록순 조회 테스트 및 확인      
        exec p_wcategory_rank('A1');
-- 전체 카테고리별 등록순 예외 발생.        
        exec p_wcategory_rank('A10');

        
        --6-1. 뷰
        create or replace view v_ctgr_best
        as
        select p_name , p_price , TOTAL_SALES , ctgr_name
        from product p join category c on p.ctgr_code = c.ctgr_code
        order by TOTAL_SALES desc;
        --6-2.        >상세 카테고리별 인기순<
         create or replace procedure mkp_child_ctgrBEST
        ( -- 카테고리를 파라미터로 받으면 입고별로 나옴 ex(우유, 두유, 요거트)
         pctgr_name category.ctgr_name%type
        )
        is -- 선언부
         vdsql varchar2(2000);
         vcursor SYS_REFCURSOR;
         vrow v_ctgr_BEST%rowtype;
         mk_e_search exception;
        begin -- 실행부
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
            DBMS_OUTPUT.PUT_LINE('키워드 다시 입력해 주세요.');
        end;
-- 상세 카테고리별 인기순 테스트
    exec mkp_child_ctgrBEST('우유');
-- 상세 카테고리별 인기순 예외 발생
    exec mkp_child_ctgrBEST('샛별');



--     7-1.  뷰
    create or replace view v_ctgr_Wbest
    as
    select p_name, p_price, ctgr_top , c.ctgr_name, total_sales
    from category c left join product p on p.ctgr_code = c.ctgr_code 
    where p_name is not null
    order by ctgr_top asc, total_sales desc ;      
        
--     7-2.        >전체 카테고리별 인기순<
create or replace procedure p_wcategory_rank
        ( -- 전체카테고리 코드 입력받음 ex A1
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
             dbms_output.put_line( '키워드 다시 입력하세요.' );
        end;        
-- 전체 카테고리별 인기순 테스트
exec p_wcategory_rank('H1');
-- 전체 카테고리별 인기순 예외 테스트
exec p_wcategory_rank('H10');

