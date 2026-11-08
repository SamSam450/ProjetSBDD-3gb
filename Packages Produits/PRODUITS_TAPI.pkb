create or replace PACKAGE BODY produits_tapi AS
    -- Variable globale pour logger avec le nom du package en dur
    gc_scope_prefix CONSTANT VARCHAR2(31) := 'produits_tapi.';

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
        p_prix                        IN produits.prix%TYPE,
        p_qte_dispo                   IN produits.qte_dispo%TYPE DEFAULT NULL,
        p_description                 IN produits.description%TYPE DEFAULT NULL,
        p_catégorie_id_catégorie   IN produits.catégorie_id_catégorie%TYPE,
        p_nom                         IN produits.nom%TYPE,
        p_test                        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 AS
        l_scope         VARCHAR2(200) := gc_scope_prefix || 'ins_produit';
        l_id_produit    produits.id_produit%TYPE;
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_nom_null     EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_nom_null, -1400);
    BEGIN
        logger.log('>>>DÉBUT de la procédure ins_produit', l_scope);

        INSERT INTO produits (
            prix, qte_dispo, description, catégorie_id_catégorie, nom
        ) VALUES (
            p_prix, p_qte_dispo, p_description, p_catégorie_id_catégorie, p_nom
        ) RETURNING id_produit INTO l_id_produit;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'produits',
                'id'         VALUE l_id_produit,
                'attributes' VALUE JSON_OBJECT(
                    'prix'                 VALUE p_prix,
                    'qteDispo'             VALUE p_qte_dispo,
                    'description'          VALUE p_description,
                    'catégorieIdCatégorie' VALUE p_catégorie_id_catégorie,
                    'nom'                  VALUE p_nom
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 201
            )
        );

        logger.log('>>>FIN de la procédure ins_produit', l_scope);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_nom_null THEN
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_nom_null', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'Nom du produit requis',
                        'detail'  VALUE 'Erreur nom null lors de l insertion du produit ORA-01400',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l insertion du produit',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
    END ins_produit;

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
        p_id_produit                  IN produits.id_produit%TYPE,
        p_prix                        IN produits.prix%TYPE DEFAULT NULL,
        p_qte_dispo                   IN produits.qte_dispo%TYPE DEFAULT NULL,
        p_description                 IN produits.description%TYPE DEFAULT NULL,
        p_catégorie_id_catégorie   IN produits.catégorie_id_catégorie%TYPE DEFAULT NULL,
        p_nom                         IN produits.nom%TYPE DEFAULT NULL,
        p_test                        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(200) := gc_scope_prefix || 'upd_produit';
        r_produit       produits%ROWTYPE;
        l_nbre_rangee   NUMBER;
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_id_is_null   EXCEPTION;
    BEGIN
        logger.log('>>>DÉBUT de la procédure upd_produit', l_scope);

        IF p_id_produit IS NULL THEN
            RAISE ex_id_is_null;
        END IF;

        SELECT * INTO r_produit
        FROM produits
        WHERE id_produit = p_id_produit;

        UPDATE produits
        SET
            prix = COALESCE(p_prix, r_produit.prix),
            qte_dispo = COALESCE(p_qte_dispo, r_produit.qte_dispo),
            description = COALESCE(p_description, r_produit.description),
            catégorie_id_catégorie = COALESCE(p_catégorie_id_catégorie, r_produit.catégorie_id_catégorie),
            nom = COALESCE(p_nom, r_produit.nom)
        WHERE id_produit = p_id_produit;

        l_nbre_rangee := SQL%ROWCOUNT;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'produits',
                'id'         VALUE p_id_produit,
                'attributes' VALUE JSON_OBJECT(
                    'prix'                 VALUE COALESCE(p_prix, r_produit.prix),
                    'qteDispo'             VALUE COALESCE(p_qte_dispo, r_produit.qte_dispo),
                    'description'          VALUE COALESCE(p_description, r_produit.description),
                    'catégorieIdCatégorie' VALUE COALESCE(p_catégorie_id_catégorie, r_produit.catégorie_id_catégorie),
                    'nom'                  VALUE COALESCE(p_nom, r_produit.nom)
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );

        logger.log('>>>FIN de la procédure upd_produit', l_scope);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID du produit requis',
                        'detail'  VALUE 'Erreur id est null lors de la maj du produit',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN NO_DATA_FOUND THEN
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_inexistant', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Produit non trouvé',
                        'detail'  VALUE 'Erreur id inexistant ' || p_id_produit || ' lors de la maj du produit',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la mise à jour du produit',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
    END upd_produit;

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
        p_id_produit                  IN produits.id_produit%TYPE,
        p_test                        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(200) := gc_scope_prefix || 'del_produit';
        l_nbre_rangee   NUMBER;
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_id_is_null   EXCEPTION;
        ex_id_inexistant EXCEPTION;
    BEGIN
        logger.log('>>>DÉBUT de la procédure del_produit', l_scope);

        IF p_id_produit IS NULL THEN
            RAISE ex_id_is_null;
        END IF;

        DELETE FROM produits
        WHERE id_produit = p_id_produit;

        l_nbre_rangee := SQL%ROWCOUNT;

        IF l_nbre_rangee = 0 THEN
            RAISE ex_id_inexistant;
        END IF;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type' VALUE 'produits',
                'id'   VALUE p_id_produit
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );

        logger.log('>>>FIN de la procédure del_produit', l_scope);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID du produit requis',
                        'detail'  VALUE 'Erreur id est null lors de l effacement du produit',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN ex_id_inexistant THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_inexistant', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Produit non trouvé',
                        'detail'  VALUE 'Erreur id inexistant ' || p_id_produit || ' lors de l effacement du produit',
                        'code'    VALUE TO_CHAR(-2),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l effacement du produit',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
    END del_produit;

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
        p_id_produit                  IN produits.id_produit%TYPE DEFAULT NULL,
        p_limite                      IN NUMBER DEFAULT 5,
        p_debut                       IN NUMBER DEFAULT 0,
        p_taille                      IN NUMBER DEFAULT 4
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(200) := gc_scope_prefix || 'get_produit';
        l_reponse       VARCHAR2(4000);
        l_json_produits VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_aucun_produit EXCEPTION;
    BEGIN
        logger.log('>>>DÉBUT de la procédure get_produit', l_scope);

        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'type'       VALUE 'produits',
                'id'         VALUE id_produit,
                'attributes' VALUE JSON_OBJECT(
                    'prix'                 VALUE prix,
                    'qteDispo'             VALUE qte_dispo,
                    'description'          VALUE description,
                    'catégorieIdCatégorie' VALUE catégorie_id_catégorie,
                    'nom'                  VALUE nom
                )
            )
        ) INTO l_json_produits
        FROM produits
        WHERE id_produit = COALESCE(p_id_produit, id_produit)
        OFFSET p_debut ROWS FETCH NEXT 
            CASE WHEN p_limite > 0 THEN LEAST(p_limite, p_taille) ELSE p_taille END 
        ROWS ONLY;

        IF l_json_produits IS NULL THEN
            RAISE ex_aucun_produit;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE l_json_produits FORMAT JSON,
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200,
                'pagination' VALUE JSON_OBJECT(
                    'offset' VALUE p_debut,
                    'limit'  VALUE CASE WHEN p_limite > 0 THEN LEAST(p_limite, p_taille) ELSE p_taille END
                )
            )
        );

        logger.log('>>>FIN de la procédure get_produit', l_scope);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_aucun_produit THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_aucun_produit', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Produit non trouvé',
                        'detail'  VALUE 'Aucun produit trouvé pour cette recherche',
                        'code'    VALUE TO_CHAR(-20001),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la récupération du produit',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
    END get_produit;

END produits_tapi;