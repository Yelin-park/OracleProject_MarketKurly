CREATE OR REPLACE PROCEDURE mk_p_logon
(
    p_c_id sign_up.c_id%TYPE,
    p_c_pwd sign_up.c_pwd%TYPE
)
IS
    v_c_pwd sign_up.c_pwd%TYPE;
    v_logonCheck NUMBER(1);
    v_c_code sign_up.c_code%TYPE;
BEGIN
    SELECT COUNT(*) INTO v_logonCheck
    FROM sign_up
    WHERE c_id = p_c_id;
    
    SELECT c_code INTO v_c_code
    FROM sign_up
    WHERE c_id = p_c_id;   
    
    IF v_logonCheck != 0 THEN
        SELECT c_pwd INTO v_c_pwd
        FROM sign_up
        WHERE c_id = p_c_id;
        
        IF v_c_pwd = p_c_pwd THEN
            v_logonCheck := 1;
            DBMS_OUTPUT.PUT_LINE(v_c_code||'�� ȸ�� : '||'�α��� ����');
        ELSE
            v_logonCheck := 0;
            DBMS_OUTPUT.PUT_LINE('���̵� �Ǵ� ��й�ȣ �����Դϴ�.');
        END IF;
    ELSE 
        v_logonCheck := 0;
        DBMS_OUTPUT.PUT_LINE('���̵� �Ǵ� ��й�ȣ �����Դϴ�.');
    END IF;
END;



EXEC mk_p_logon('elephont99', 'passtree3399');