Prompt Création du package spec de tests test_produits_tapi.
CREATE OR REPLACE PACKAGE test_produits_tapi IS
    /**
     * Description    Tests utPLSQL du package produits_tapi
     *
     * @version      2.0.0                catégorie créée dans les tests, p_test => 'O', tests de validation
     * @author       Claude
     * @created      2026-11-26
     */

    --%suite(test_produits_tapi)
    --%suitepath(alltests)
    --%rollback(auto)

    -- INSERT
    --%test(ins_produit normal: insertion d'un produit et retour du statut 201)
    PROCEDURE ins_produit;

    --%test(ins_produit_prix_null: le prix est obligatoire, erreur 400)
    PROCEDURE ins_produit_prix_null;

    --%test(ins_produit_prix_negatif: le prix doit être >= 0, erreur 400)
    PROCEDURE ins_produit_prix_negatif;

    --%test(ins_produit_categorie_null: la catégorie est obligatoire, erreur 400)
    PROCEDURE ins_produit_categorie_null;

    --%test(ins_produit_nom_null: le nom est obligatoire, erreur 400)
    PROCEDURE ins_produit_nom_null;

    --%test(ins_produit_plusieurs_erreurs: une erreur par champ obligatoire manquant)
    PROCEDURE ins_produit_plusieurs_erreurs;

    --%test(ins_produit_categorie_inexistante: catégorie inexistante, erreur 404 ORA-02291)
    PROCEDURE ins_produit_categorie_inexistante;

    -- UPDATE
    --%test(upd_produit normal: modification du prix et du nom d'un produit)
    PROCEDURE upd_produit;

    --%test(upd_produit_partiel: les champs non fournis restent inchangés)
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

    --%test(get_produit_inexistant: aucun produit trouvé, erreur 404)
    PROCEDURE get_produit_inexistant;

    --%test(get_produit_tous: extraction sans identifiant)
    PROCEDURE get_produit_tous;

    --%test(get_produit_pagination_taille: p_taille limite le nombre de produits retournés)
    PROCEDURE get_produit_pagination_taille;

    --%test(get_produit_debut_hors_limite: p_debut après la dernière ligne, erreur 404)
    PROCEDURE get_produit_debut_hors_limite;

    --%test(get_produit_taille_invalide: p_taille à 0, erreur 400)
    PROCEDURE get_produit_taille_invalide;

END test_produits_tapi;
/
SHOW ERRORS;
