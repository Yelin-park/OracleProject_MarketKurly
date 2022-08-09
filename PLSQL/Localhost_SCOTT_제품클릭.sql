-- [클릭]
-- 내용 
-- 1. a 고객이 b상품을 클릭하면 상품 페이지 보여주기
-- 2. 클릭한 제품들은 [클릭] 테이블에 7개까지 등록
-- 3. [최근 본상품] 목록 보여주기
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 클릭 시퀀스
CREATE SEQUENCE click_code_seq
INCREMENT BY 1
START WITH 1
NOMAXVALUE
MINVALUE 1
NOCYCLE;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--회원이 상품을 클릭하면 최근 상품 7개까지 저장하는 프로시저
CREATE OR REPLACE PROCEDURE mk_p_click_insert
(
    p_c_code customer.c_code%TYPE,
    p_p_code product.p_code%TYPE
)
IS
    v_click_sum NUMBER;
    v_p_code click.p_code%TYPE;
    CURSOR dup_check_cursor IS (SELECT p_code FROM click WHERE c_code = p_c_code);
BEGIN  
    OPEN dup_check_cursor;
    LOOP
        FETCH dup_check_cursor INTO v_p_code;
        EXIT WHEN dup_check_cursor%NOTFOUND;
        DELETE FROM click WHERE p_code = v_p_code AND p_code = p_p_code;
    END LOOP;
    CLOSE dup_check_cursor;
    
    SELECT COUNT(click_code) 
    INTO v_click_sum 
    FROM click 
    WHERE c_code = p_c_code;

    IF v_click_sum < 7 THEN

        INSERT INTO click (click_code, c_code, p_code)
        VALUES (click_code_seq.nextval, p_c_code, p_p_code);
    ELSE
        DELETE FROM click 
        WHERE click_code = (SELECT MIN(click_code) FROM click WHERE c_code = p_c_code);
        INSERT INTO click (click_code, c_code, p_code)
        VALUES (click_code_seq.nextval, p_c_code, p_p_code);
    END IF;
    COMMIT;
END;


EXEC mk_p_click_insert (1,5);
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--최근 본 상품 목록을 보여주는 프로시저
CREATE OR REPLACE PROCEDURE mk_p_recent_view
(p_c_code customer.c_code%TYPE)
IS
    v_p_code click.p_code%TYPE;
    v_p_name product.p_name%TYPE;
    CURSOR recent_view_cursor IS (SELECT p_code FROM click WHERE c_code = p_c_code);
    v_count NUMBER := 0;
BEGIN
    OPEN recent_view_cursor;
    LOOP
        v_count := v_count + 1;
        FETCH recent_view_cursor INTO v_p_code;
        EXIT WHEN recent_view_cursor%NOTFOUND;
        SELECT p_name INTO v_p_name FROM product WHERE p_code = v_p_code;
        DBMS_OUTPUT.PUT_LINE( '(' ||v_count || ')' || v_p_name );
    END LOOP;
    CLOSE recent_view_cursor;
END;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--상품 클릭하는 프로시저
CREATE OR REPLACE PROCEDURE mk_p_product_click
(
    p_c_code customer.c_code%TYPE,
    p_p_code product.p_code%TYPE
)
IS
    v_product_name product.p_name%TYPE;
    v_p_price product.p_price%TYPE;
    v_p_discount product.p_discount%TYPE;
    v_img_file product_img.file_path%TYPE;
    v_detail_type product_detail.pd_type%TYPE;
    v_detail_content product_detail.pd_content%TYPE;
    row_review review%ROWTYPE;
    row_qa question%ROWTYPE;
    v_name sign_up.c_name%TYPE;
    v_answer_state VARCHAR2(20);
    CURSOR img_cursor IS (
        SELECT file_path 
        FROM product_img 
        WHERE p_code = p_p_code);
    CURSOR detail_cursor IS (
        SELECT pd_type, pd_content 
        FROM product_detail 
        WHERE p_code = p_p_code);
    CURSOR review_curor IS(
        SELECT rtitle, c_name, r_date, r_help, r_check
        FROM review r JOIN sign_up s ON r.c_code = s.c_code
        WHERE r.p_code = p_p_code);
    CURSOR QA_curor IS(
        SELECT q_title, c_name, q_sysd, q_state
        FROM question q JOIN sign_up s ON q.c_code = s.c_code
        WHERE q.p_code = p_p_code);
    
    v_count NUMBER;
BEGIN
    SELECT p_name, p_price, p_discount
    INTO v_product_name, v_p_price, v_p_discount
    FROM product 
    WHERE p_code = p_p_code;
    
    DBMS_OUTPUT.PUT_LINE ('상품이름 : '|| v_product_name);
    DBMS_OUTPUT.PUT_LINE ('가격(원가) : '|| v_p_price||'원');
    IF v_p_discount > 0 THEN
        DBMS_OUTPUT.PUT_LINE ('할인(' || v_p_discount*100 || '%) : ' || v_p_price*(1-v_p_discount)||'원');
    END IF;
    DBMS_OUTPUT.PUT_LINE ('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    OPEN img_cursor;
    v_count := 0;
    LOOP
        v_count := v_count + 1;
        FETCH img_cursor INTO v_img_file;
        EXIT WHEN img_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE (v_count || '번 이미지 : '||v_img_file);
    END LOOP;
    CLOSE img_cursor;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('');
    
    OPEN detail_cursor;
    LOOP
        FETCH detail_cursor INTO v_detail_type, v_detail_content;
        EXIT WHEN detail_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('['||v_detail_type||']');
        DBMS_OUTPUT.PUT_LINE(v_detail_content);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    CLOSE detail_cursor;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    
    
    DBMS_OUTPUT.PUT_LINE('[최근 본 상품]');
    mk_p_recent_view(p_c_code);
    
    mk_p_click_insert (p_c_code,p_p_code);
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('[후기]');
    
    OPEN review_curor;
    v_count := 0;
    LOOP
        v_count := v_count + 1;
        FETCH review_curor INTO row_review.rtitle, v_name, row_review.r_date, row_review.r_help, row_review.r_check;
        EXIT WHEN review_curor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('[' ||v_count||']'||row_review.rtitle);
        DBMS_OUTPUT.PUT_LINE('    (' ||v_name||' / '||row_review.r_date||' / 도움 : '||row_review.r_help||' / 조회 : '||row_review.r_check||')');
    END LOOP;
    CLOSE review_curor;
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('[질문]');
    OPEN QA_curor;
    v_count := 0;
    LOOP
        v_count := v_count + 1;
        FETCH QA_curor INTO row_qa.q_title, v_name, row_qa.q_sysd, row_qa.q_state;
        EXIT WHEN QA_curor%NOTFOUND;
        IF row_qa.q_state = 0 THEN v_answer_state := '-';
        ELSE v_answer_state := '완료';
        END IF;
        DBMS_OUTPUT.PUT_LINE('[' ||v_count||']'||row_qa.q_title);
        DBMS_OUTPUT.PUT_LINE('    (' ||v_name||' / '||row_qa.q_sysd||' / 답변 : '||v_answer_state||')');
    END LOOP;
    CLOSE QA_curor;
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
END;

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--[테스트]
BEGIN
    mk_p_product_click (
    1, -- n번 회원이 
    1 -- m번 상품 클릭
    );
END;
