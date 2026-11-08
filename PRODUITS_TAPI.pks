create or replace PACKAGE produits_tapi IS
    /**
     * Description    Fonction pour insérer un nouveau produit
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
     * @example      l_resultat := produits_tapi.ins_produit(19.99, 10, 'Description test', 1, 'Gâteau au chocolat', 'N');
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_prix                    prix unitaire du produit
     * @param        p_qte_dispo               quantité disponible en stock
     * @param        p_description             description détaillée du produit
     * @param        p_catégorie_id_catégorie  identifiant de la catégorie associée
     * @param        p_nom                     nom du produit
     * @param        p_test                    paramètre pour les tests ('Y' pour éviter le commit, 'N' par défaut)
     * @return       l_reponse                 objet JSON avec un status 201, les attributs et la clé primaire id_produit créée
     * @exception    ex_nom_null               si le nom du produit est null (ORA-01400), retourné dans un objet JSON avec status 400
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION ins_produit (
        p_prix                    IN produits.prix%TYPE,
        p_qte_dispo               IN produits.qte_dispo%TYPE DEFAULT NULL,
        p_description             IN produits.description%TYPE DEFAULT NULL,
        p_catégorie_id_catégorie  IN produits.catégorie_id_catégorie%TYPE,
        p_nom                     IN produits.nom%TYPE,
        p_test                    IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /**
     * Description    Fonction pour mettre à jour un produit existant
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et format JSON:API
     * @example      l_resultat := produits_tapi.upd_produit(p_id_produit => 1, p_prix => 24.99);
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_id_produit              identifiant unique du produit à modifier
     * @param        p_prix                    nouveau prix du produit (optionnel)
     * @param        p_qte_dispo               nouvelle quantité disponible (optionnelle)
     * @param        p_description             nouvelle description (optionnelle)
     * @param        p_catégorie_id_catégorie  nouvel identifiant de catégorie (optionnel)
     * @param        p_nom                     nouveau nom du produit (optionnel)
     * @param        p_test                    paramètre pour les tests ('Y' ou 'N')
     * @return       l_reponse                 objet JSON avec un status 200 et les attributs mis à jour
     * @exception    ex_id_is_null             si l'identifiant du produit est null, retourné en objet JSON avec status 400
     * @exception    NO_DATA_FOUND             si le produit n'existe pas en base de données, retourné avec status 404
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION upd_produit (
        p_id_produit              IN produits.id_produit%TYPE,
        p_prix                    IN produits.prix%TYPE DEFAULT NULL,
        p_qte_dispo               IN produits.qte_dispo%TYPE DEFAULT NULL,
        p_description             IN produits.description%TYPE DEFAULT NULL,
        p_catégorie_id_catégorie  IN produits.catégorie_id_catégorie%TYPE DEFAULT NULL,
        p_nom                     IN produits.nom%TYPE DEFAULT NULL,
        p_test                    IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /**
     * Description    Fonction pour supprimer un produit par son identifiant
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et format JSON:API
     * @example      l_resultat := produits_tapi.del_produit(p_id_produit => 1, p_test => 'N');
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_id_produit              identifiant unique du produit à supprimer
     * @param        p_test                    paramètre pour les tests ('Y' ou 'N')
     * @return       l_reponse                 objet JSON avec un status 200 confirmant la suppression
     * @exception    ex_id_is_null             si l'identifiant fourni est null, retourné avec status 400
     * @exception    ex_id_inexistant          si aucun produit ne correspond à cet identifiant, retourné avec status 404
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION del_produit (
        p_id_produit  IN produits.id_produit%TYPE,
        p_test        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /**
     * Description    Fonction pour récupérer un ou plusieurs produits avec pagination
     *
     * @version      2.1.0                refonte pour utiliser JSON_ARRAYAGG et gestion de la pagination
     * @example      l_resultat := produits_tapi.get_produit(p_id_produit => NULL, p_limite => 5, p_debut => 0, p_taille => 4);
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_id_produit              identifiant optionnel pour cibler un produit spécifique
     * @param        p_limite                  nombre maximum de résultats à retourner
     * @param        p_debut                   décalage (offset) pour la pagination
     * @param        p_taille                  taille de lot par défaut pour la pagination
     * @return       l_reponse                 tableau JSON des produits au format de données et métadonnées de pagination
     * @exception    ex_aucun_produit          si aucun produit n'est trouvé pour la recherche, retourné avec status 404
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION get_produit (
        p_id_produit  IN produits.id_produit%TYPE DEFAULT NULL,
        p_limite      IN NUMBER DEFAULT 5,
        p_debut       IN NUMBER DEFAULT 0,
        p_taille      IN NUMBER DEFAULT 4
    ) RETURN VARCHAR2;

END produits_tapi;