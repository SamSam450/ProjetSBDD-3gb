create or replace PACKAGE BODY produits_tapi AS
    /**
     * Description    Fonction pour insérer un nouveau produit
     *
     * @version      2.2.0                validation des paramètres obligatoires, 404 catégorie inexistante, attributs JSON sans accent
     * @example      l_resultat := produits_tapi.ins_produit(19.99, 10, 'Description test', 1, 'Gâteau au chocolat', 'N');
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_prix                    prix unitaire du produit (obligatoire, >= 0)
     * @param        p_qte_dispo               quantité disponible en stock
     * @param        p_description             description détaillée du produit
     * @param        p_catégorie_id_catégorie  identifiant de la catégorie associée (obligatoire)
     * @param        p_nom                     nom du produit (obligatoire)
     * @param        p_test                    paramètre pour les tests ('O' pour éviter le commit, 'N' par défaut)
     * @return       l_reponse                 objet JSON avec un status 201, les attributs et la clé primaire id_produit créée
     * @exception    validation                paramètre obligatoire absent ou prix négatif, une erreur par champ, status 400
     * @exception    ex_categorie_inexistante  si la catégorie n'existe pas (ORA-02291), status 404
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION ins_produit (
        p_prix                        IN produits.prix%TYPE,
        p_qte_dispo                   IN produits.qte_dispo%TYPE DEFAULT NULL,
        p_description                 IN produits.description%TYPE DEFAULT NULL,
        p_catégorie_id_catégorie      IN produits.catégorie_id_catégorie%TYPE,
        p_nom                         IN produits.nom%TYPE,
        p_test                        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 AS
        l_scope         VARCHAR2(200) := LOWER($$plsql_unit) || '.ins_produit';
        l_params        logger.tab_param;
        l_id_produit    produits.id_produit%TYPE;
        l_reponse       VARCHAR2(4000);
        l_error_code    NUMBER;
        l_erreurs       JSON_ARRAY_T := JSON_ARRAY_T();
        l_racine        JSON_OBJECT_T;
        ex_nom_null     EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_nom_null, -1400);
        ex_categorie_inexistante EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_categorie_inexistante, -2291);

        PROCEDURE ajouter_erreur (p_detail IN VARCHAR2) IS
            l_erreur JSON_OBJECT_T := JSON_OBJECT_T();
            l_meta   JSON_OBJECT_T := JSON_OBJECT_T();
        BEGIN
            l_meta.put('timestamp', TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'));
            l_erreur.put('status', '400');
            l_erreur.put('title',  'Validation échouée');
            l_erreur.put('detail', p_detail);
            l_erreur.put('code',   '-1');
            l_erreur.put('meta',   l_meta);
            l_erreurs.append(l_erreur);
        END ajouter_erreur;
    BEGIN
        logger.append_param(l_params, 'p_prix', p_prix);
        logger.append_param(l_params, 'p_qte_dispo', p_qte_dispo);
        logger.append_param(l_params, 'p_description', p_description);
        logger.append_param(l_params, 'p_catégorie_id_catégorie', p_catégorie_id_catégorie);
        logger.append_param(l_params, 'p_nom', p_nom);
        logger.append_param(l_params, 'p_test', p_test);
        logger.log('>>>DÉBUT de la procédure ins_produit', l_scope, NULL, l_params);

        -- Validation des paramètres obligatoires (une erreur par champ)
        IF p_prix IS NULL THEN
            ajouter_erreur('Le prix du produit est obligatoire');
        ELSIF p_prix < 0 THEN
            ajouter_erreur('Le prix du produit doit être supérieur ou égal à 0');
        END IF;

        IF p_catégorie_id_catégorie IS NULL THEN
            ajouter_erreur('La catégorie du produit est obligatoire');
        END IF;

        IF p_nom IS NULL THEN
            ajouter_erreur('Le nom du produit est obligatoire');
        END IF;

        IF l_erreurs.get_size > 0 THEN
            logger.log_warn('>>>ERREUR de validation des paramètres', l_scope, NULL, l_params);
            l_racine := JSON_OBJECT_T();
            l_racine.put('errors', l_erreurs);
            RETURN l_racine.to_string;
        END IF;

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
                    'categorieIdCategorie' VALUE p_catégorie_id_catégorie,
                    'nom'                  VALUE p_nom
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 201
            )
        );

        logger.log('>>>FIN de la procédure ins_produit', l_scope, NULL, l_params);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_categorie_inexistante THEN
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_categorie_inexistante', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Catégorie non trouvée',
                        'detail'  VALUE 'La catégorie ' || p_catégorie_id_catégorie || ' n''existe pas',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN ex_nom_null THEN
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_nom_null', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'Valeur obligatoire manquante',
                        'detail'  VALUE 'Une colonne obligatoire est null lors de l''insertion du produit (ORA-01400)',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l''insertion du produit',
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
     * @version      2.2.0                attributs JSON sans accent, journalisation des paramètres
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
     * @param        p_test                    paramètre pour les tests ('O' pour éviter le commit, 'N' par défaut)
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
        p_catégorie_id_catégorie      IN produits.catégorie_id_catégorie%TYPE DEFAULT NULL,
        p_nom                         IN produits.nom%TYPE DEFAULT NULL,
        p_test                        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(200) := LOWER($$plsql_unit) || '.upd_produit';
        l_params        logger.tab_param;
        r_produit       produits%ROWTYPE;
        l_reponse       VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_id_is_null   EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_produit', p_id_produit);
        logger.append_param(l_params, 'p_prix', p_prix);
        logger.append_param(l_params, 'p_qte_dispo', p_qte_dispo);
        logger.append_param(l_params, 'p_description', p_description);
        logger.append_param(l_params, 'p_catégorie_id_catégorie', p_catégorie_id_catégorie);
        logger.append_param(l_params, 'p_nom', p_nom);
        logger.append_param(l_params, 'p_test', p_test);
        logger.log('>>>DÉBUT de la procédure upd_produit', l_scope, NULL, l_params);

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
                    'categorieIdCategorie' VALUE COALESCE(p_catégorie_id_catégorie, r_produit.catégorie_id_catégorie),
                    'nom'                  VALUE COALESCE(p_nom, r_produit.nom)
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );

        logger.log('>>>FIN de la procédure upd_produit', l_scope, NULL, l_params);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope, NULL, l_params);
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
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_inexistant', l_scope, NULL, l_params);
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
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope, NULL, l_params);
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
     * @version      2.2.0                409 si le produit est commandé, journalisation des paramètres
     * @example      l_resultat := produits_tapi.del_produit(p_id_produit => 1, p_test => 'N');
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_id_produit              identifiant unique du produit à supprimer
     * @param        p_test                    paramètre pour les tests ('O' pour éviter le commit, 'N' par défaut)
     * @return       l_reponse                 objet JSON avec un status 200 confirmant la suppression
     * @exception    ex_id_is_null             si l'identifiant fourni est null, retourné avec status 400
     * @exception    ex_id_inexistant          si aucun produit ne correspond à cet identifiant, retourné avec status 404
     * @exception    ex_produit_commande       si le produit est référencé par une commande (ORA-02292), retourné avec status 409
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION del_produit (
        p_id_produit                  IN produits.id_produit%TYPE,
        p_test                        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(200) := LOWER($$plsql_unit) || '.del_produit';
        l_params        logger.tab_param;
        l_nbre_rangee   NUMBER;
        l_reponse       VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_id_is_null   EXCEPTION;
        ex_id_inexistant EXCEPTION;
        ex_produit_commande EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_produit_commande, -2292);
    BEGIN
        logger.append_param(l_params, 'p_id_produit', p_id_produit);
        logger.append_param(l_params, 'p_test', p_test);
        logger.log('>>>DÉBUT de la procédure del_produit', l_scope, NULL, l_params);

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

        logger.log('>>>FIN de la procédure del_produit', l_scope, NULL, l_params);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID du produit requis',
                        'detail'  VALUE 'Erreur id est null lors de l''effacement du produit',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN ex_id_inexistant THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_inexistant', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Produit non trouvé',
                        'detail'  VALUE 'Erreur id inexistant ' || p_id_produit || ' lors de l''effacement du produit',
                        'code'    VALUE TO_CHAR(-2),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN ex_produit_commande THEN
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_produit_commande', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '409',
                        'title'   VALUE 'Produit commandé',
                        'detail'  VALUE 'Le produit ' || p_id_produit || ' est référencé par une commande et ne peut pas être supprimé',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            l_error_code := SQLCODE;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l''effacement du produit',
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
     * @version      2.2.0                pagination dans une sous-requête avant JSON_ARRAYAGG, un seul paramètre de taille
     * @example      l_resultat := produits_tapi.get_produit(p_id_produit => NULL, p_debut => 0, p_taille => 4);
     * @issue        problème xyz
     * @author       Sid Ali Ouchiha
     * @created      2026-11-05
     * @param        p_id_produit              identifiant optionnel pour cibler un produit spécifique
     * @param        p_debut                   décalage (offset) pour la pagination (>= 0)
     * @param        p_taille                  nombre de produits retournés par page (> 0)
     * @return       l_reponse                 tableau JSON des produits au format de données et métadonnées de pagination
     * @exception    ex_params_invalides       si p_debut ou p_taille est invalide, retourné avec status 400
     * @exception    ex_aucun_produit          si aucun produit n'est trouvé pour la recherche, retourné avec status 404
     * @exception    OTHERS                    exception autre non traitée, retournée dans un objet JSON avec status 500
     */
    FUNCTION get_produit (
        p_id_produit                  IN produits.id_produit%TYPE DEFAULT NULL,
        p_debut                       IN NUMBER DEFAULT 0,
        p_taille                      IN NUMBER DEFAULT 4
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(200) := LOWER($$plsql_unit) || '.get_produit';
        l_params        logger.tab_param;
        l_reponse       VARCHAR2(4000);
        l_json_produits VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_params_invalides EXCEPTION;
        ex_aucun_produit EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_produit', p_id_produit);
        logger.append_param(l_params, 'p_debut', p_debut);
        logger.append_param(l_params, 'p_taille', p_taille);
        logger.log('>>>DÉBUT de la procédure get_produit', l_scope, NULL, l_params);

        IF p_debut IS NULL OR p_debut < 0 OR p_taille IS NULL OR p_taille <= 0 THEN
            RAISE ex_params_invalides;
        END IF;

        -- La pagination est faite dans la sous-requête, avant JSON_ARRAYAGG
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'type'       VALUE 'produits',
                'id'         VALUE id_produit,
                'attributes' VALUE JSON_OBJECT(
                    'prix'                 VALUE prix,
                    'qteDispo'             VALUE qte_dispo,
                    'description'          VALUE description,
                    'categorieIdCategorie' VALUE catégorie_id_catégorie,
                    'nom'                  VALUE nom
                )
            ) ORDER BY id_produit
        ) INTO l_json_produits
        FROM (
            SELECT id_produit, prix, qte_dispo, description, catégorie_id_catégorie, nom
            FROM produits
            WHERE id_produit = COALESCE(p_id_produit, id_produit)
            ORDER BY id_produit
            OFFSET p_debut ROWS FETCH NEXT p_taille ROWS ONLY
        );

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
                    'limit'  VALUE p_taille
                )
            )
        );

        logger.log('>>>FIN de la procédure get_produit', l_scope, NULL, l_params);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_params_invalides THEN
            logger.log_error('>>>ERREUR de type ex_params_invalides', l_scope, NULL, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'Paramètres de pagination invalides',
                        'detail'  VALUE 'p_debut doit être >= 0 et p_taille doit être > 0',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;
        WHEN ex_aucun_produit THEN
            logger.log_error('>>>ERREUR de type ex_aucun_produit', l_scope, NULL, l_params);
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
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope, NULL, l_params);
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
/
