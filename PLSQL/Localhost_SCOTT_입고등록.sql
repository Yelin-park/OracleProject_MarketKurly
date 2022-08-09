-- 입고내역 코드 시퀀스
CREATE SEQUENCE wh_code_seq
INCREMENT BY 1
START WITH 16
NOMAXVALUE
MINVALUE 1
NOCYCLE;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- [입고 내역] 등록 프로시저
CREATE OR REPLACE PROCEDURE mk_p_add_wh
(
    p_p_code product.p_code%TYPE,
    p_db_center_code db_center.db_center_code%TYPE,
    p_expiration_date wh_history.expiration_date%TYPE,
    p_count wh_history.count%TYPE
)
IS
    ex_foreignkey EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_foreignkey, -02291);
BEGIN
    INSERT INTO wh_history
    VALUES(
        wh_code_seq.nextval,
        p_p_code,
        p_db_center_code,
        SYSDATE,
        p_expiration_date,
        TRUNC(p_expiration_date - SYSDATE),
        p_count
    );
    COMMIT;
EXCEPTION
    WHEN ex_foreignkey THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20202, '>상품이나 물류센터가 없습니다.<');
END;

BEGIN
mk_p_add_wh(
    1, -- 1번 상품
    7, -- 1번 물류센터로
    '2022.05.31', --2022.05.31까지 유통기한인 상품
    50 -- 50개
);
END;

ROLLBACK;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[입고내역] 등록 시, [재고] 인서트나 업데이트 되는 트리거
CREATE OR REPLACE TRIGGER mk_t_wh_inven AFTER
INSERT OR DELETE ON wh_history
FOR EACH ROW
DECLARE
    v_check NUMBER;
BEGIN
    IF INSERTING THEN
    
        SELECT COUNT(*) INTO v_check
        FROM inventory 
        WHERE  p_code = :NEW.p_code 
        AND db_center_code = :NEW.db_center_code;
        
        IF v_check > 0 THEN
            UPDATE inventory
            SET i_count = i_count + :NEW.count
            WHERE p_code = :NEW.p_code 
            AND db_center_code = :NEW.db_center_code;
        ELSE -- 해당물류센터에 해당 제품이 없다면
            INSERT INTO inventory
            VALUES (i_code_seq.nextval, :NEW.db_center_code, :NEW.p_code, :NEW.count);
        END IF;
        
    ELSIF DELETING THEN
    
        UPDATE inventory
        SET i_count = i_count - :OLD.count
        WHERE p_code = :OLD.p_code AND db_center_code = :OLD.db_center_code;
        
    END IF;
END;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[테스트]
BEGIN
mk_p_add_wh(
    1, -- 1번 상품
    7, -- 1번 물류센터로
    '2022.05.31', --2022.05.31까지 유통기한인 상품
    50 -- 50개
);
END;

ROLLBACK;


