CREATE OR REPLACE PACKAGE test_categorie_tapi AS
    -- %suite(Tests unitaires pour le package Categorie TAPI)
    -- %suitepath(tapi.categorie)

    -- %test(Tester l insertion d une categorie avec succes)
    -- %rollback(manual)
    PROCEDURE test_ins_categorie;

    -- %test(Tester l insertion d une categorie avec un nom NULL (Erreur ORA-01400))
    -- %rollback(manual)
    PROCEDURE test_ins_categorie_null;

    -- %test(Tester la recuperation get_categorie par ID)
    -- %rollback(manual)
    PROCEDURE test_get_categorie_par_id;

    -- %test(Tester la mise a jour d une categorie)
    -- %rollback(manual)
    PROCEDURE test_upd_categorie;

    -- %test(Tester la suppression d une categorie)
    -- %rollback(manual)
    PROCEDURE test_del_categorie;

    -- %test(Tester la suppression d un ID inexistant (Erreur -2))
    -- %rollback(manual)
    PROCEDURE test_del_categorie_inexistant;

END test_categorie_tapi;

/


CREATE OR REPLACE PACKAGE BODY test_categorie_tapi AS

    PROCEDURE test_ins_categorie IS
        l_res VARCHAR2(4000);
    BEGIN
        -- Nettoyage préventif
        BEGIN
            DELETE FROM catégorie WHERE id_categorie = 999;
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;

        -- Act
        l_res := categorie_tapi.ins_categorie(
            p_id_categorie  => 999, 
            p_nom_categorie => 'Test Patisserie', 
            p_test          => 'Y'
        );

        -- Nettoyage final
        DELETE FROM catégorie WHERE id_categorie = 999;
        COMMIT;

        -- Assert
        ut.expect(l_res).to_be_not_null();
        ut.expect(l_res).to_be_like('%success%');
    END test_ins_categorie;

    PROCEDURE test_ins_categorie_null IS
        l_res VARCHAR2(4000);
    BEGIN
        -- Act (Doit intercepter l'erreur de nom null)
        l_res := categorie_tapi.ins_categorie(
            p_id_categorie  => 998, 
            p_nom_categorie => NULL, 
            p_test          => 'Y'
        );

        -- Assert
        ut.expect(l_res).to_be_not_null();
        ut.expect(l_res).to_be_like('%errors%');
    END test_ins_categorie_null;

    PROCEDURE test_get_categorie_par_id IS
        l_res VARCHAR2(4000);
    BEGIN
        -- Setup : insérer la catégorie pour le test de lecture
        BEGIN
            DELETE FROM catégorie WHERE id_categorie = 999;
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        INSERT INTO catégorie (id_categorie, nom) VALUES (999, 'Test Get');
        COMMIT;

        -- Act
        l_res := categorie_tapi.get_categorie(p_id_categorie => 999);

        -- Nettoyage
        DELETE FROM catégorie WHERE id_categorie = 999;
        COMMIT;

        -- Assert
        ut.expect(l_res).to_be_not_null();
        ut.expect(l_res).to_be_like('%success%');
    END test_get_categorie_par_id;

    PROCEDURE test_upd_categorie IS
        l_res VARCHAR2(4000);
    BEGIN
        -- Setup : insérer la catégorie à modifier
        BEGIN
            DELETE FROM catégorie WHERE id_categorie = 999;
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        INSERT INTO catégorie (id_categorie, nom) VALUES (999, 'Avant Update');
        COMMIT;

        -- Act
        l_res := categorie_tapi.upd_categorie(
            p_id_categorie => 999,
            p_nom          => 'Patisserie Fine',
            p_test         => 'Y'
        );

        -- Nettoyage
        DELETE FROM catégorie WHERE id_categorie = 999;
        COMMIT;

        -- Assert
        ut.expect(l_res).to_be_not_null();
        ut.expect(l_res).to_be_like('%success%');
    END test_upd_categorie;

    PROCEDURE test_del_categorie IS
        l_res VARCHAR2(4000);
    BEGIN
        -- Setup : insérer la catégorie à supprimer
        BEGIN
            DELETE FROM catégorie WHERE id_categorie = 999;
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
        INSERT INTO catégorie (id_categorie, nom) VALUES (999, 'A Supprimer');
        COMMIT;

        -- Act
        l_res := categorie_tapi.del_categorie(
            p_id_categorie => 999,
            p_test         => 'Y'
        );

        -- Assert
        ut.expect(l_res).to_be_not_null();
        ut.expect(l_res).to_be_like('%success%');
    END test_del_categorie;

    PROCEDURE test_del_categorie_inexistant IS
        l_res VARCHAR2(4000);
    BEGIN
        -- Act (Doit intercepter l'erreur d'ID inexistant)
        l_res := categorie_tapi.del_categorie(
            p_id_categorie => -8888,
            p_test         => 'Y'
        );

        -- Assert
        ut.expect(l_res).to_be_not_null();
        ut.expect(l_res).to_be_like('%errors%');
    END test_del_categorie_inexistant;

END test_categorie_tapi;

/
