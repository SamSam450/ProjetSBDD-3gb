Prompt Création du package spec de tests test_produits_tapi.
CREATE OR REPLACE PACKAGE test_produits_tapi IS

    --%suite(test_produits_tapi)
    --%suitepath(alltests)
    --%rollback(auto)

    -- INSERT
    --%test(ins_produit normal: insertion d'un produit et retour du statut 201)
    PROCEDURE ins_produit;

    --%test(ins_produit_nom_null: le nom est obligatoire, erreur 400 ORA-01400)
    PROCEDURE ins_produit_nom_null;

    --%test(ins_produit_categorie_inexistante: violation de la cle etrangere, erreur 500 ORA-02291)
    PROCEDURE ins_produit_categorie_inexistante;

    -- UPDATE
    --%test(upd_produit normal: modification du prix et du nom d'un produit)
    PROCEDURE upd_produit;

    --%test(upd_produit_partiel: les champs non fournis restent inchanges)
    PROCEDURE upd_produit_partiel;

    --%test(upd_produit_id_null: identifiant null, erreur 400)
    PROCEDURE upd_produit_id_null;

    --%test(upd_produit_inexistant: identifiant inexistant, erreur 404)
    PROCEDURE upd_produit_inexistant;

    -- DELETE
    --%test(del_produit normal: suppression d'un produit existant)
    PROCEDURE del_produit;

    --%test(del_produit_id_null: identifiant null, erreur 400)
    PROCEDURE del_produit_id_null;

    --%test(del_produit_inexistant: identifiant inexistant, erreur 404)
    PROCEDURE del_produit_inexistant;

    -- GET
    --%test(get_produit normal: extraction d'un produit par son identifiant)
    PROCEDURE get_produit;

    --%test(get_produit_inexistant: aucun produit trouve, erreur 404)
    PROCEDURE get_produit_inexistant;

    --%test(get_produit_tous: extraction sans identifiant)
    PROCEDURE get_produit_tous;

    --%test(get_produit_pagination_limite: p_limite plus petit que p_taille limite le nombre de produits)
    PROCEDURE get_produit_pagination_limite;

    --%test(get_produit_pagination_taille_max: p_limite plus grand que p_taille est plafonne a p_taille)
    PROCEDURE get_produit_pagination_taille_max;

    --%test(get_produit_pagination_limite_zero: p_limite a 0 utilise p_taille)
    PROCEDURE get_produit_pagination_limite_zero;

END test_produits_tapi;
/
SHOW ERRORS;
