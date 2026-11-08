CREATE OR REPLACE package test_utilisateur_tapi is

   --%suite(test_utilisateur_tapi)
    --%suitepath(alltests)

    -- GET
    --%test(get_utilisateur_normal)
    PROCEDURE get_utilisateur;

    --%test(get_utilisateur_inexistant)
    PROCEDURE get_utilisateur_inexistant;

    -- DELETE
    --%test(del_utilisateur_normal)
    PROCEDURE del_utilisateur;

    --%test(del_utilisateur_inexistant)
    PROCEDURE del_utilisateur_inexistant;

    --%test(del_utilisateur_id_null)
    PROCEDURE del_utilisateur_id_null;

    -- UPDATE
    --%test(upd_utilisateur_normal)
    PROCEDURE upd_utilisateur;

    --%test(upd_utilisateur_id_null)
    PROCEDURE upd_utilisateur_id_null;

    --%test(upd_utilisateur_inexistant)
    PROCEDURE upd_utilisateur_inexistant;

    -- INSERT
    --%test(ins_utilisateur_normal)
    PROCEDURE ins_utilisateur;

    --%test(ins_utilisateur_params_obligatoires_null)
    PROCEDURE ins_utilisateur_ex_params_obli;

END test_utilisateur_tapi;

/


CREATE OR REPLACE PACKAGE BODY test_utilisateur_tapi IS

    -- ==========================================
    -- GET
    -- ==========================================

    PROCEDURE get_utilisateur IS
        l_id_user utilisateur.id_user%TYPE;
        l_id_retourne utilisateur.id_user%TYPE;
        l_reponse VARCHAR2(4000);
        l_status VARCHAR2(50);
    BEGIN
        -- Arrange
        SELECT MIN(id_user)
        INTO l_id_user
        FROM utilisateur;

        -- Act
        l_reponse := utilisateur_tapi.get_utilisateur(l_id_user);

        -- Assert
        l_id_retourne := TO_NUMBER(
            JSON_VALUE(l_reponse, '$.data[0].id')
        );

        l_status := JSON_VALUE(l_reponse, '$.meta.status');

        ut.expect(l_id_retourne).to_equal(l_id_user);
        ut.expect(l_status).to_equal('success');

    END get_utilisateur;


    PROCEDURE get_utilisateur_inexistant IS
        l_reponse VARCHAR2(4000);
        l_code VARCHAR2(20);
    BEGIN
        -- Arrange
        -- On choisit un ID qui ne devrait pas exister.

        -- Act
        l_reponse := utilisateur_tapi.get_utilisateur(-99999);

        -- Assert
        l_code := JSON_VALUE(l_reponse, '$.errors[0].code');

        ut.expect(l_code).to_equal('-20001');

    END get_utilisateur_inexistant;


    -- ==========================================
    -- DELETE
    -- ==========================================

    PROCEDURE del_utilisateur IS
        l_reponse VARCHAR2(4000);
        l_reponse_ins VARCHAR2(4000);
        l_id_user utilisateur.id_user%TYPE;
        l_id_retourne utilisateur.id_user%TYPE;
        l_status VARCHAR2(50);
    BEGIN
        -- Arrange
        l_reponse_ins := utilisateur_tapi.ins_utilisateur(
            'Utilisateur test delete',
            'motdepasse123',
            'delete@test.com',
            'O'
        );

        l_id_user := TO_NUMBER(
            JSON_VALUE(l_reponse_ins, '$.data.id')
        );

        -- Act
        l_reponse := utilisateur_tapi.del_utilisateur(
            l_id_user,
            'O'
        );

        -- Assert
        l_id_retourne := TO_NUMBER(
            JSON_VALUE(l_reponse, '$.data.id')
        );

        l_status := JSON_VALUE(l_reponse, '$.meta.status');

        ut.expect(l_id_retourne).to_equal(l_id_user);
        ut.expect(l_status).to_equal('success');

    END del_utilisateur;


    PROCEDURE del_utilisateur_inexistant IS
        l_reponse VARCHAR2(4000);
        l_code VARCHAR2(20);
    BEGIN
        -- Arrange
        -- ID inexistant.

        -- Act
        l_reponse := utilisateur_tapi.del_utilisateur(
            -99999,
            'O'
        );

        -- Assert
        l_code := JSON_VALUE(l_reponse, '$.errors[0].code');

        ut.expect(l_code).to_equal('-2');

    END del_utilisateur_inexistant;


    PROCEDURE del_utilisateur_id_null IS
        l_reponse VARCHAR2(4000);
        l_code VARCHAR2(20);
    BEGIN
        -- Arrange
        -- Aucun ID.

        -- Act
        l_reponse := utilisateur_tapi.del_utilisateur(
            NULL,
            'O'
        );

        -- Assert
        l_code := JSON_VALUE(l_reponse, '$.errors[0].code');

        ut.expect(l_code).to_equal('-1');

    END del_utilisateur_id_null;


    -- ==========================================
    -- UPDATE
    -- ==========================================

    PROCEDURE upd_utilisateur IS
        l_reponse_ins VARCHAR2(4000);
        l_reponse VARCHAR2(4000);
        l_id_user utilisateur.id_user%TYPE;
        l_id_retourne utilisateur.id_user%TYPE;
        l_nom_bd utilisateur.nom%TYPE;
        l_status VARCHAR2(50);
    BEGIN
        -- Arrange
        l_reponse_ins := utilisateur_tapi.ins_utilisateur(
            'Utilisateur avant update',
            'motdepasse123',
            'update@test.com',
            'O'
        );

        l_id_user := TO_NUMBER(
            JSON_VALUE(l_reponse_ins, '$.data.id')
        );

        -- Act
        l_reponse := utilisateur_tapi.upd_utilisateur(
            p_id_user => l_id_user,
            p_nom => 'Utilisateur apres update',
            p_test => 'O'
        );

        -- Assert
        l_id_retourne := TO_NUMBER(
            JSON_VALUE(l_reponse, '$.data.id')
        );

        l_status := JSON_VALUE(l_reponse, '$.meta.status');

        SELECT nom
        INTO l_nom_bd
        FROM utilisateur
        WHERE id_user = l_id_user;

        ut.expect(l_id_retourne).to_equal(l_id_user);
        ut.expect(l_status).to_equal('success');
        ut.expect(l_nom_bd).to_equal('Utilisateur apres update');

    END upd_utilisateur;


    PROCEDURE upd_utilisateur_id_null IS
        l_reponse VARCHAR2(4000);
        l_code VARCHAR2(20);
    BEGIN
        -- Arrange
        -- Aucun ID.

        -- Act
        l_reponse := utilisateur_tapi.upd_utilisateur(
            p_id_user => NULL,
            p_test => 'O'
        );

        -- Assert
        l_code := JSON_VALUE(l_reponse, '$.errors[0].code');

        ut.expect(l_code).to_equal('-1');

    END upd_utilisateur_id_null;


    PROCEDURE upd_utilisateur_inexistant IS
        l_reponse VARCHAR2(4000);
        l_code VARCHAR2(20);
    BEGIN
        -- Arrange
        -- ID inexistant.

        -- Act
        l_reponse := utilisateur_tapi.upd_utilisateur(
            p_id_user => -99999,
            p_test => 'O'
        );

        -- Assert
        l_code := JSON_VALUE(l_reponse, '$.errors[0].code');

        ut.expect(l_code).to_equal('100');

    END upd_utilisateur_inexistant;


    -- ==========================================
    -- INSERT
    -- ==========================================

    PROCEDURE ins_utilisateur IS
        l_reponse VARCHAR2(4000);
        l_id_user utilisateur.id_user%TYPE;
        l_status VARCHAR2(50);
        l_status_code NUMBER;
    BEGIN
        -- Arrange
        -- Préparation des informations du nouvel utilisateur.

        -- Act
        l_reponse := utilisateur_tapi.ins_utilisateur(
            'Utilisateur test insert',
            'motdepasse123',
            'insert@test.com',
            'O'
        );

        -- Assert
        l_id_user := TO_NUMBER(
            JSON_VALUE(l_reponse, '$.data.id')
        );

        l_status := JSON_VALUE(l_reponse, '$.meta.status');

        l_status_code := TO_NUMBER(
            JSON_VALUE(l_reponse, '$.meta.statusCode')
        );

        ut.expect(l_id_user).to_be_not_null();
        ut.expect(l_status).to_equal('success');
        ut.expect(l_status_code).to_equal(201);

    END ins_utilisateur;


    PROCEDURE ins_utilisateur_ex_params_obli IS
        l_reponse VARCHAR2(4000);
        l_code VARCHAR2(20);
    BEGIN
        -- Arrange
        -- Le nom obligatoire sera NULL.

        -- Act
        l_reponse := utilisateur_tapi.ins_utilisateur(
            NULL,
            'motdepasse123',
            NULL,
            'O'
        );

        -- Assert
        l_code := JSON_VALUE(l_reponse, '$.errors[0].code');

        ut.expect(l_code).to_equal('-1400');

    END ins_utilisateur_ex_params_obli;


END test_utilisateur_tapi;
/
