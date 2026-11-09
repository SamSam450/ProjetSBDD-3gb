CREATE OR REPLACE PACKAGE categorie_tapi AS
    -- Fonction d'insertion
    FUNCTION ins_categorie (
        p_id_categorie  catégorie.id_categorie%TYPE,
        p_nom_categorie catégorie.nom%TYPE,
        p_test          VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    -- Fonction de mise à jour
    FUNCTION upd_categorie (
        p_id_categorie IN catégorie.id_categorie%TYPE,
        p_nom          IN catégorie.nom%TYPE DEFAULT NULL,
        p_test         VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    -- Fonction de suppression
    FUNCTION del_categorie (
        p_id_categorie IN catégorie.id_categorie%TYPE,
        p_test         VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    -- Fonction de sélection 
    FUNCTION get_categorie (
        p_id_categorie IN catégorie.id_categorie%TYPE,
        p_limite       IN NUMBER DEFAULT 5,
        p_debut        IN NUMBER DEFAULT 0,
        p_taille       IN NUMBER DEFAULT 4
    ) RETURN VARCHAR2;
END categorie_tapi;

/


CREATE OR REPLACE PACKAGE BODY categorie_tapi AS
    -- variable globale pour logger afin de contenir le nom du package
    gc_scope_prefix CONSTANT VARCHAR2(31) := lower($$plsql_unit) || '.';


    /**
     * Description    fonction pour insérer une catégorie
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
     *
     * @example      l_resultant := categorie_tapi.ins_categorie (1, 'patisserie');
     *
     * @issue        n/a
     *
     * @author       Julien Pelletier
     * @created      2026-11-8
     * @param        p_id_categorie      id de la catégorie
     * @param        p_nom_categorie     nom de la catégorie
     * @param        p_test              paramètre pour ne pas sauvegarder les tests, si 'N' alors commit
     * @return       l_reponse           objet JSON avec un status et la clé primaire id_categorie de la catégorie créée
     * @exception    ex_nom_categorie_null si le nom de la catégorie est null, retourné dans un objet JSON avec status et code d erreur -1400
     * @exception    OTHERS              exception autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
     */
    FUNCTION ins_categorie (
        p_id_categorie  catégorie.id_categorie%TYPE,
        p_nom_categorie catégorie.nom%TYPE,
        p_test          VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 AS
        l_scope         logger_logs.scope%type := gc_scope_prefix || 'ins_categorie';
        l_params        logger.tab_param;
        l_id_categorie  catégorie.id_categorie%type;
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_nom_categorie_null EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_nom_categorie_null, -1400);
    BEGIN
        logger.append_param(l_params, 'p_id_categorie: ', p_id_categorie);
        logger.append_param(l_params, 'p_nom_categorie: ', p_nom_categorie);

        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);

        INSERT INTO catégorie (
            id_categorie, nom
        ) VALUES (
            p_id_categorie, p_nom_categorie
        ) RETURNING id_categorie INTO l_id_categorie;

        logger.append_param(l_params, 'l_id_categorie: ', l_id_categorie);

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'categorie',
                'id'         VALUE l_id_categorie,
                'attributes' VALUE JSON_OBJECT(
                    'nom'        VALUE p_nom_categorie
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 201
            )
        );

        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_nom_categorie_null THEN
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_nom_categorie_null', l_scope, null, l_params);

            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'Nom de la categorie requis',
                        'detail'  VALUE 'Erreur nom null lors de l insertion de la categorie ORA-01400',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'))
                    )
                )
            );
            RETURN l_reponse;

        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope, null, l_params);

            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur interne de la base de données',
                        'detail'  VALUE 'Erreur non gérée lors de l insertion de la categorie: ' || l_error_mess,
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END ins_categorie;


    /**
     * Description    fonction pour mettre à jour une catégorie - ATTENTION cette fonction ne peut pas mettre une colonne à null
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
     *
     * @example      l_resultat := categorie_tapi.upd_categorie (1, 'nouvelle_patisserie');
     *
     * @issue        n/a
     *
     * @author       Julien Pelletier
     * @created      2026-11-8
     * @param        p_id_categorie      la clé primaire de la catégorie à mettre à jour
     * @param        p_nom               nom de la catégorie
     * @param        p_test              paramètre pour ne pas sauvegarder les tests, si 'N' alors commit
     * @return       l_reponse           objet JSON avec un status et la clé primaire id_categorie de la catégorie mise à jour
     * @exception    ex_id_is_null       si le paramètre p_id_categorie est null, retourne dans un objet JSON avec status et code d erreur -1
     * @exception    NO_DATA_FOUND       si aucune rangée dans la table ne correspond au p_id_categorie
     * @exception    OTHERS              exception autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
     */
    FUNCTION upd_categorie (
        p_id_categorie IN catégorie.id_categorie%TYPE,
        p_nom          IN catégorie.nom%TYPE DEFAULT NULL,
        p_test         VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         logger_logs.scope%type := gc_scope_prefix || 'upd_categorie';
        l_params        logger.tab_param;
        l_id_categorie  catégorie.id_categorie%type;
        r_categorie     catégorie%rowtype;
        l_nbre_rangee   NUMBER;
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_id_is_null   EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_categorie: ', p_id_categorie);
        logger.append_param(l_params, 'p_nom: ', p_nom);
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);

        IF p_id_categorie IS NULL THEN
            RAISE ex_id_is_null;
        END IF;

        SELECT * INTO r_categorie
        FROM catégorie
        WHERE id_categorie = p_id_categorie;

        UPDATE catégorie
        SET nom = COALESCE(p_nom, r_categorie.nom)
        WHERE id_categorie = p_id_categorie
        RETURNING id_categorie INTO l_id_categorie;

        l_nbre_rangee := sql%rowcount;
        logger.append_param(l_params, 'sql%l_nbre_rangee: ', l_nbre_rangee);
        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'categorie',
                'id'         VALUE l_id_categorie,
                'attributes' VALUE JSON_OBJECT(
                    'nom'        VALUE p_nom
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null dans la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID de la categorie requis',
                        'detail'  VALUE 'Erreur id est null lors de la maj de la categorie',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;

        WHEN NO_DATA_FOUND THEN
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type NO_DATA_FOUND dans la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Categorie non trouvee',
                        'detail'  VALUE 'Erreur id inexistant ' || p_id_categorie || ' lors de la maj de la categorie',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;

        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            logger.log_error('>>>ERREUR de type OTHERS dans la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur systeme',
                        'detail'  VALUE 'Erreur OTHERS lors de la mise a jour de la categorie',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END upd_categorie;


    /**
     * Description    fonction pour effacer une catégorie
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
     *
     * @example      l_resultat := categorie_tapi.del_categorie (12);
     *
     * @issue        n/a
     *
     * @author       Julien Pelletier
     * @created      2026-11-8
     * @param        p_id_categorie      la clé primaire de la catégorie à effacer
     * @param        p_test              paramètre pour ne pas sauvegarder les tests, si 'N' alors commit
     * @return       l_reponse           objet JSON avec un status et la clé primaire id_categorie de la catégorie effacée
     * @exception    ex_id_is_null       si le paramètre p_id_categorie est null, retourne dans un objet JSON avec status et code d erreur -1
     * @exception    ex_id_inexistant    si aucune rangée dans la table ne correspond au p_id_categorie, code d erreur -2
     * @exception    OTHERS              exception autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
     */
    FUNCTION del_categorie (
        p_id_categorie IN catégorie.id_categorie%TYPE,
        p_test         VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         logger_logs.scope%type := gc_scope_prefix || 'del_categorie';
        l_params        logger.tab_param;
        l_nbre_rangee   NUMBER;
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_id_is_null   EXCEPTION;
        ex_id_inexistant EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_categorie: ', p_id_categorie);
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);

        IF p_id_categorie IS NULL THEN
            RAISE ex_id_is_null;
        END IF;        

        DELETE FROM catégorie
        WHERE id_categorie = p_id_categorie;

        l_nbre_rangee := sql%rowcount;
        logger.append_param(l_params, 'SQL%ROWCOUNT: ', sql%rowcount);
        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);

        IF l_nbre_rangee = 0 THEN
            RAISE ex_id_inexistant;
        END IF;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'  VALUE 'categorie',
                'id'    VALUE p_id_categorie
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_id_is_null THEN
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID de la catégorie requis',
                        'detail'  VALUE 'Erreur id est null lors de l effacement de la catégorie',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;

        WHEN ex_id_inexistant THEN
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_inexistant', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Catégorie non trouvée',
                        'detail'  VALUE 'Erreur id inexistant ' || p_id_categorie || ' lors de l effacement de la catégorie',
                        'code'    VALUE TO_CHAR(-2),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;

        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            logger.log_error('>>>ERREUR de type OTHERS la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l effacement de la catégorie',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END del_categorie;

    /**
     * Description    fonction pour retourner les informations d une ou plusieurs catégories
     *
     * @version      2.1.0                refonte pour traiter les exceptions en tableau JSON et ajout de status, ajout de pagination (p_limite, p_debut et p_taille) et format JSON:API
     *
     * @example      l_resultat := categorie_tapi.get_categorie (12);
     *
     * @issue        n/a
     *
     * @author       Julien Pelletier
     * @created      2026-11-8
     * @param        p_id_categorie      la clé primaire de la catégorie à retourner les informations, si null retourne toutes les catégories
     * @param        p_limite            nombre de rangées maximum à retourner
     * @param        p_debut             rangée de départ
     * @param        p_taille            nombre de rangées à retourner
     * @return       l_reponse           tableau JSON qui contient les informations des catégories
     * @exception    ex_aucune_categorie si aucune catégorie ne correspond aux critères une exception est levée avec un code d erreur -20001
     * @exception    OTHERS              exception autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
     */
    FUNCTION get_categorie (
        p_id_categorie IN catégorie.id_categorie%TYPE,
        p_limite       IN NUMBER DEFAULT 5,
        p_debut        IN NUMBER DEFAULT 0,
        p_taille       IN NUMBER DEFAULT 4
    ) RETURN VARCHAR2 IS
        l_scope         logger_logs.scope%type := gc_scope_prefix || 'get_categorie';
        l_params        logger.tab_param;
        l_reponse       VARCHAR2(4000);
        l_json_cat      VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_aucune_categorie EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_categorie: ', p_id_categorie);
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);

        -- Requête pour récupérer les catégories au format JSON:API avec pagination
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'type'       VALUE 'categorie',
                'id'         VALUE id_categorie,
                'attributes' VALUE JSON_OBJECT(
                    'nom'        VALUE nom
                )
            )
        ) INTO l_json_cat
        FROM catégorie
        WHERE id_categorie = COALESCE(p_id_categorie, id_categorie)
        OFFSET p_debut ROWS FETCH NEXT 
            CASE WHEN p_limite > 0 THEN LEAST(p_limite, p_taille) ELSE p_taille END 
        ROWS ONLY;

        IF l_json_cat IS NULL THEN
            RAISE ex_aucune_categorie;
        END IF;

        -- Formatage de la réponse conforme à JSON:API
        l_reponse := JSON_OBJECT(
            'data' VALUE l_json_cat FORMAT JSON,
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200,
                'pagination' VALUE JSON_OBJECT(
                    'offset' VALUE p_debut,
                    'limit'  VALUE CASE WHEN p_limite > 0 THEN LEAST(p_limite, p_taille) ELSE p_taille END
                )
            )
        );
        logger.append_param(l_params, 'l_reponse: ', l_reponse);
        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_aucune_categorie THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_aucune_categorie', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Catégorie non trouvée',
                        'detail'  VALUE 'Aucune catégorie trouvée pour cette recherche',
                        'code'    VALUE TO_CHAR(-20001),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;

        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            logger.log_error('>>>ERREUR de type OTHERS la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la récupération de la catégorie',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END get_categorie;

END categorie_tapi;

/
