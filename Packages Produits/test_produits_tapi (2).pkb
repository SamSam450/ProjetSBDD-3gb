Prompt Création du package body de tests test_produits_tapi.
CREATE OR REPLACE PACKAGE BODY test_produits_tapi IS

    -- 'O' : pas de COMMIT dans produits_tapi
    g_mode_test   CONSTANT VARCHAR2(1) := 'O';

    -- Utilitaire privé : crée une catégorie de test et retourne son id
    -- (table catégorie, clé primaire id_categorie)
    FUNCTION creer_categorie_test RETURN NUMBER IS
        l_id_categorie NUMBER;
    BEGIN
        INSERT INTO catégorie (nom)
        VALUES ('Catégorie de test')
        RETURNING id_categorie INTO l_id_categorie;
        RETURN l_id_categorie;
    END creer_categorie_test;

    -- Utilitaire privé : insère un produit de test et retourne son id
    FUNCTION creer_produit_test (
        p_nom IN produits.nom%TYPE
    ) RETURN produits.id_produit%TYPE IS
        l_reponse VARCHAR2(4000);
    BEGIN
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => 19.99,
            p_qte_dispo              => 10,
            p_description            => 'Produit de test',
            p_catégorie_id_catégorie => creer_categorie_test,
            p_nom                    => p_nom,
            p_test                   => g_mode_test
        );
        RETURN TO_NUMBER(JSON_VALUE(l_reponse, '$.data.id'));
    END creer_produit_test;

    -- ==========================================
    -- INSERT
    -- ==========================================

    PROCEDURE ins_produit IS
        l_id_categorie NUMBER;
        l_reponse      VARCHAR2(4000);
        l_id_produit   produits.id_produit%TYPE;
        l_status       VARCHAR2(50);
        l_status_code  NUMBER;
        l_nom_retour   VARCHAR2(200);
        l_nb           NUMBER;
    BEGIN
        -- Arrange
        l_id_categorie := creer_categorie_test;

        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => 19.99,
            p_qte_dispo              => 10,
            p_description            => 'Gâteau au chocolat noir',
            p_catégorie_id_catégorie => l_id_categorie,
            p_nom                    => 'Gâteau test insert',
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        l_id_produit  := TO_NUMBER(JSON_VALUE(l_reponse, '$.data.id'));
        l_status      := JSON_VALUE(l_reponse, '$.meta.status');
        l_status_code := TO_NUMBER(JSON_VALUE(l_reponse, '$.meta.statusCode'));
        l_nom_retour  := JSON_VALUE(l_reponse, '$.data.attributes.nom');

        SELECT COUNT(*) INTO l_nb FROM produits WHERE id_produit = l_id_produit;

        ut.expect(l_id_produit).to_be_not_null();
        ut.expect(l_status).to_equal('success');
        ut.expect(l_status_code).to_equal(201);
        ut.expect(l_nom_retour).to_equal('Gâteau test insert');
        ut.expect(l_nb).to_equal(1);
    END ins_produit;


    PROCEDURE ins_produit_prix_null IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => NULL,
            p_catégorie_id_catégorie => creer_categorie_test,
            p_nom                    => 'Produit sans prix',
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].detail')).to_equal('Le prix du produit est obligatoire');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[1]')).to_be_null();
    END ins_produit_prix_null;


    PROCEDURE ins_produit_prix_negatif IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => -1,
            p_catégorie_id_catégorie => creer_categorie_test,
            p_nom                    => 'Produit prix négatif',
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].detail')).to_equal('Le prix du produit doit être supérieur ou égal à 0');
    END ins_produit_prix_negatif;


    PROCEDURE ins_produit_categorie_null IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => 19.99,
            p_catégorie_id_catégorie => NULL,
            p_nom                    => 'Produit sans catégorie',
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].detail')).to_equal('La catégorie du produit est obligatoire');
    END ins_produit_categorie_null;


    PROCEDURE ins_produit_nom_null IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => 19.99,
            p_qte_dispo              => 10,
            p_description            => 'Produit sans nom',
            p_catégorie_id_catégorie => creer_categorie_test,
            p_nom                    => NULL,
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].detail')).to_equal('Le nom du produit est obligatoire');
    END ins_produit_nom_null;


    PROCEDURE ins_produit_plusieurs_erreurs IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => NULL,
            p_catégorie_id_catégorie => NULL,
            p_nom                    => NULL,
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].detail')).to_equal('Le prix du produit est obligatoire');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[1].detail')).to_equal('La catégorie du produit est obligatoire');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[2].detail')).to_equal('Le nom du produit est obligatoire');
    END ins_produit_plusieurs_erreurs;


    PROCEDURE ins_produit_categorie_inexistante IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.ins_produit(
            p_prix                   => 19.99,
            p_qte_dispo              => 10,
            p_description            => 'Produit catégorie invalide',
            p_catégorie_id_catégorie => -99999,
            p_nom                    => 'Produit FK invalide',
            p_test                   => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(COALESCE(JSON_VALUE(l_reponse, '$.errors[0].code'), '-99999')).to_equal('-2291');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('404');
    END ins_produit_categorie_inexistante;


    -- ==========================================
    -- UPDATE
    -- ==========================================

    PROCEDURE upd_produit IS
        l_id_produit    produits.id_produit%TYPE;
        l_reponse       VARCHAR2(4000);
        l_id_retourne   produits.id_produit%TYPE;
        l_status        VARCHAR2(50);
        l_status_code   NUMBER;
        l_nom_bd        produits.nom%TYPE;
        l_prix_bd       produits.prix%TYPE;
    BEGIN
        -- Arrange
        l_id_produit := creer_produit_test('Produit avant update');

        -- Act
        l_reponse := produits_tapi.upd_produit(
            p_id_produit => l_id_produit,
            p_prix       => 24.99,
            p_nom        => 'Produit apres update',
            p_test       => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        l_id_retourne := TO_NUMBER(JSON_VALUE(l_reponse, '$.data.id'));
        l_status      := JSON_VALUE(l_reponse, '$.meta.status');
        l_status_code := TO_NUMBER(JSON_VALUE(l_reponse, '$.meta.statusCode'));

        SELECT nom, prix INTO l_nom_bd, l_prix_bd
        FROM produits
        WHERE id_produit = l_id_produit;

        ut.expect(l_id_retourne).to_equal(l_id_produit);
        ut.expect(l_status).to_equal('success');
        ut.expect(l_status_code).to_equal(200);
        ut.expect(l_nom_bd).to_equal('Produit apres update');
        ut.expect(l_prix_bd).to_equal(24.99);
    END upd_produit;


    PROCEDURE upd_produit_partiel IS
        l_id_produit    produits.id_produit%TYPE;
        l_reponse       VARCHAR2(4000);
        l_nom_bd        produits.nom%TYPE;
        l_qte_bd        produits.qte_dispo%TYPE;
        l_desc_bd       produits.description%TYPE;
        l_prix_bd       produits.prix%TYPE;
    BEGIN
        -- Arrange
        l_id_produit := creer_produit_test('Produit partiel');

        -- Act
        l_reponse := produits_tapi.upd_produit(
            p_id_produit => l_id_produit,
            p_prix       => 5.50,
            p_test       => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        SELECT nom, qte_dispo, description, prix
        INTO l_nom_bd, l_qte_bd, l_desc_bd, l_prix_bd
        FROM produits
        WHERE id_produit = l_id_produit;

        ut.expect(l_prix_bd).to_equal(5.50);
        ut.expect(l_nom_bd).to_equal('Produit partiel');
        ut.expect(l_qte_bd).to_equal(10);
        ut.expect(l_desc_bd).to_equal('Produit de test');
    END upd_produit_partiel;


    PROCEDURE upd_produit_id_null IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.upd_produit(
            p_id_produit => NULL,
            p_test       => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(COALESCE(JSON_VALUE(l_reponse, '$.errors[0].code'), '-99999')).to_equal('-1');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
    END upd_produit_id_null;


    PROCEDURE upd_produit_inexistant IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.upd_produit(
            p_id_produit => -99999,
            p_prix       => 10,
            p_test       => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(COALESCE(JSON_VALUE(l_reponse, '$.errors[0].code'), '-99999')).to_equal('100');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('404');
    END upd_produit_inexistant;


    -- ==========================================
    -- DELETE
    -- ==========================================

    PROCEDURE del_produit IS
        l_id_produit  produits.id_produit%TYPE;
        l_reponse     VARCHAR2(4000);
        l_id_retourne produits.id_produit%TYPE;
        l_status      VARCHAR2(50);
        l_status_code NUMBER;
        l_nb          NUMBER;
    BEGIN
        -- Arrange
        l_id_produit := creer_produit_test('Produit a supprimer');

        -- Act
        l_reponse := produits_tapi.del_produit(
            p_id_produit => l_id_produit,
            p_test       => g_mode_test
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        l_id_retourne := TO_NUMBER(JSON_VALUE(l_reponse, '$.data.id'));
        l_status      := JSON_VALUE(l_reponse, '$.meta.status');
        l_status_code := TO_NUMBER(JSON_VALUE(l_reponse, '$.meta.statusCode'));

        SELECT COUNT(*) INTO l_nb FROM produits WHERE id_produit = l_id_produit;

        ut.expect(l_id_retourne).to_equal(l_id_produit);
        ut.expect(l_status).to_equal('success');
        ut.expect(l_status_code).to_equal(200);
        ut.expect(l_nb).to_equal(0);
    END del_produit;


    PROCEDURE del_produit_id_null IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.del_produit(NULL, g_mode_test);
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(COALESCE(JSON_VALUE(l_reponse, '$.errors[0].code'), '-99999')).to_equal('-1');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
    END del_produit_id_null;


    PROCEDURE del_produit_inexistant IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.del_produit(-99999, g_mode_test);
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(COALESCE(JSON_VALUE(l_reponse, '$.errors[0].code'), '-99999')).to_equal('-2');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('404');
    END del_produit_inexistant;


    -- ==========================================
    -- GET
    -- ==========================================

    PROCEDURE get_produit IS
        l_id_produit  produits.id_produit%TYPE;
        l_reponse     VARCHAR2(4000);
        l_id_retourne produits.id_produit%TYPE;
        l_nom_retour  VARCHAR2(200);
        l_status      VARCHAR2(50);
    BEGIN
        -- Arrange
        l_id_produit := creer_produit_test('Produit a lire');

        -- Act
        l_reponse := produits_tapi.get_produit(p_id_produit => l_id_produit);
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        l_id_retourne := TO_NUMBER(JSON_VALUE(l_reponse, '$.data[0].id'));
        l_nom_retour  := JSON_VALUE(l_reponse, '$.data[0].attributes.nom');
        l_status      := JSON_VALUE(l_reponse, '$.meta.status');

        ut.expect(l_id_retourne).to_equal(l_id_produit);
        ut.expect(l_nom_retour).to_equal('Produit a lire');
        ut.expect(l_status).to_equal('success');
    END get_produit;


    PROCEDURE get_produit_inexistant IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.get_produit(p_id_produit => -99999);
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(COALESCE(JSON_VALUE(l_reponse, '$.errors[0].code'), '-99999')).to_equal('-20001');
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('404');
    END get_produit_inexistant;


    PROCEDURE get_produit_tous IS
        l_id_produit  produits.id_produit%TYPE;
        l_reponse     VARCHAR2(4000);
    BEGIN
        -- Arrange
        l_id_produit := creer_produit_test('Produit liste');

        -- Act
        l_reponse := produits_tapi.get_produit();
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.meta.status')).to_equal('success');
        ut.expect(JSON_VALUE(l_reponse, '$.data[0].id')).to_be_not_null();
    END get_produit_tous;


    PROCEDURE get_produit_pagination_taille IS
        l_id_1       produits.id_produit%TYPE;
        l_reponse    VARCHAR2(4000);
    BEGIN
        -- Arrange
        l_id_1 := creer_produit_test('Pagination 1');
        l_id_1 := creer_produit_test('Pagination 2');
        l_id_1 := creer_produit_test('Pagination 3');

        -- Act
        l_reponse := produits_tapi.get_produit(
            p_id_produit => NULL,
            p_debut      => 0,
            p_taille     => 2
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(TO_NUMBER(JSON_VALUE(l_reponse, '$.meta.pagination.limit'))).to_equal(2);
        ut.expect(TO_NUMBER(JSON_VALUE(l_reponse, '$.meta.pagination.offset'))).to_equal(0);
        ut.expect(JSON_VALUE(l_reponse, '$.data[1].id')).to_be_not_null();
        ut.expect(JSON_VALUE(l_reponse, '$.data[2].id')).to_be_null();
    END get_produit_pagination_taille;


    PROCEDURE get_produit_debut_hors_limite IS
        l_id_produit  produits.id_produit%TYPE;
        l_reponse     VARCHAR2(4000);
    BEGIN
        -- Arrange
        l_id_produit := creer_produit_test('Produit offset');

        -- Act : un seul produit correspond, l'offset 1 dépasse la dernière ligne
        l_reponse := produits_tapi.get_produit(
            p_id_produit => l_id_produit,
            p_debut      => 1,
            p_taille     => 1
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('404');
    END get_produit_debut_hors_limite;


    PROCEDURE get_produit_taille_invalide IS
        l_reponse VARCHAR2(4000);
    BEGIN
        -- Act
        l_reponse := produits_tapi.get_produit(
            p_id_produit => NULL,
            p_debut      => 0,
            p_taille     => 0
        );
        DBMS_OUTPUT.PUT_LINE('l_reponse: ' || l_reponse);

        -- Assert
        ut.expect(JSON_VALUE(l_reponse, '$.errors[0].status')).to_equal('400');
    END get_produit_taille_invalide;

END test_produits_tapi;
/
SHOW ERRORS;
