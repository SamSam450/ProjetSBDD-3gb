CREATE OR REPLACE PACKAGE utilisateur_tapi IS
  --select
    FUNCTION get_utilisateur (
        p_ID_user utilisateur.id_user%type
    ) RETURN VARCHAR2;

    -- delete
    FUNCTION del_utilisateur (
        p_id_user IN utilisateur.id_user%TYPE, p_test VARCHAR2 DEFAULT 'N'
    )
    return VARCHAR2;

    -- update
    FUNCTION upd_utilisateur (
        p_id_user IN utilisateur.id_user%TYPE, p_nom IN utilisateur.nom%TYPE DEFAULT NULl, 
        p_password IN utilisateur.motdepasse%TYPE DEFAULT NULL, p_email IN utilisateur.email%TYPE DEFAULT NULL,
        p_test VARCHAR2 DEFAULT 'N'
    )
    return VARCHAR2;

    -- insert
    FUNCTION ins_utilisateur (
         p_nom IN utilisateur.nom%TYPE, p_password IN utilisateur.motdepasse%TYPE, 
         p_email IN utilisateur.email%TYPE DEFAULT NULL, p_test VARCHAR2 DEFAULT 'N')
    return VARCHAR2;

END utilisateur_tapi;
/


CREATE OR REPLACE PACKAGE BODY utilisateur_tapi AS
    -- variable global pour logger afin de contenir le nom du package
    gc_scope_prefix CONSTANT VARCHAR2(31) := lower($$plsql_unit) || '.';
 /**

    * Description fonction pour retourner les information d'un utilisateur 
    *
    * @version      2.1.0           refonte pour traiter les exceptions en tableau JSON et ajout de status, et format JSON:API
    *
    * @example      l_resultat := utilisateur_tapi.get_utilisateur (12);
    *
    * @issue        n/a
    * @author       JF Brodeur/ Modification Samuel Geoffroy
    * @created      2023-11-2
    * @param        p_id_user           la clé primaire du cours à retourner les informations, si null retourne tous les cours
    * @return       l_reponse           tableau JSON qui contient les informations des cours
    * @exception    ex_aucun_user      si aucun cours ne correspond aux critères une exception Oracle est levée avec un code d erreur -20001
    * @exception    OTHERS              excepttion autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
    */
    FUNCTION get_utilisateur (
        p_ID_user utilisateur.id_user%type

    ) RETURN VARCHAR2 IS
        l_scope         logger_logs.scope%type := gc_scope_prefix || 'get_utilisateur';
        l_params        logger.tab_param;
        l_reponse       VARCHAR2(4000);
        l_json_user    VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_aucun_cours  EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_user ',p_id_user);
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);
        -- Requête pour récupérer les cours au format JSON:API
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
                'type'  VALUE 'user',
                'id'    VALUE id_user,
                'attributes' VALUE JSON_OBJECT(
                    'nom'         VALUE nom,
                    'Email' VALUE email,
                    'password'           VALUE motdepasse
                )
            )
        ) INTO l_json_user
        FROM utilisateur
        WHERE id_user=coalesce(p_id_user, id_user);




        IF l_json_user IS NULL THEN
            RAISE ex_aucun_cours;
        END IF;

        -- Formatage de la réponse conforme à JSON:API
        l_reponse := JSON_OBJECT(
            'data' VALUE l_json_user FORMAT JSON,
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200

            )
        );
        logger.append_param(l_params, 'l_reponse: ', l_reponse);
        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);
        RETURN l_reponse;
    EXCEPTION
        WHEN ex_aucun_cours THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de de type ex_aucun_cours', l_scope, null, l_params);
            -- Gestion de l'exception directement en PL/SQL au lieu de faire un RAISE_APPLICATION_ERROR
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Cours non trouvé',
                        'detail'  VALUE 'Aucun cours trouvé pour cette recherche',
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
            logger.log_error('>>>ERREUR de de type OTHERS la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la récupération de lutilisateur',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END get_utilisateur;


    /** Description fonction pour effacer un utilisateur
    *
    * @version      2.1.0               refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
    *
    * @example      utilisateur_tapi.del_utilisateur (12);
    *
    * @issue: n/a
    *
    * @author       JF Brodeur/ Modification par Samuel Geoffroy 
    * @created      2023-11-2
    * @param        p_id_user            la clé primaire de l'utlisateur  à supprimer
    * @return       l_reponse           objet JSON avec un status et la clé primaire id_cours du cours créée
    * @exception    ex_id_is_null       si le paramètre p_id_user est null, retourne dans un objet JSON avec status et code d erreur -1
    * @exception    ex_id_inexistant    si aucune rangée dans la table ne correspond au p_id_user, code d erreur -2
    * @exception    OTHERS              excepttion autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
    */
    FUNCTION del_utilisateur (
        p_id_user IN utilisateur.id_user%TYPE, p_test VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope              logger_logs.scope%type := gc_scope_prefix || 'del_utlisateur';
        l_params             logger.tab_param;
        l_nbre_rangee        NUMBER;
        l_reponse            VARCHAR2(4000);
        l_error_mess         VARCHAR2(4000);
        l_error_code         NUMBER;
        ex_id_is_null        EXCEPTION;
        ex_id_inexistant     EXCEPTION;
    BEGIN
        logger.append_param(l_params, 'p_id_user: ', p_id_user);
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);
        IF p_id_user IS NULL THEN
            RAISE ex_id_is_null;
        END IF;        
        DELETE FROM utilisateur
        WHERE
            id_user = p_id_user;
        l_nbre_rangee := sql%rowcount;
        logger.append_param(l_params, 'SQL%ROWCOUNT: ', sql%rowcount);
        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);
        IF l_nbre_rangee = 0 THEN
            RAISE ex_id_inexistant;
        END IF;
        IF p_test = 'N' THEN
            COMMIT;
        END IF;
        --creation d un objet JSON avec le status et l id_cours effacé en format JSON:API
        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'  VALUE 'utilisateur',
                'id'    VALUE p_id_user
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
            logger.log_error('>>>ERREUR de de type ex_id_is_null', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID de lutilisateur requis',
                        'detail'  VALUE 'Erreur id est null lors de l effacement de lutilisateur',
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
            logger.log_error('>>>ERREUR de de type ex_id_inexistant', l_scope, null, l_params);
            --creation d un objet JSON avec un status error et un code d erreur
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Utilisateur non trouvé',
                        'detail'  VALUE 'Erreur id inexistant '|| p_id_user ||' lors de l effacement du cours',
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
            logger.log_error('>>>ERREUR de de type OTHERS la procédure', l_scope, null, l_params);
            --creation d un objet JSON avec un status error et un code d erreur
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l effacement de lutilisateur',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END del_utilisateur;

     /**
    *Description   fonction pour mettre à jour un utilisateur - ATTENTION cette fonction ne peut pas mettre une colonne à null
    *
    * @version      2.1.0               refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
    *
    * @example      l_resultat : = utilisateur_tapi.upd_utilisateur (12,Jean-Michel);
    *
    * @issue        problème xyz
    *
    * @author       JF Brodeur /Modification par Samuel Geoffroy 
    * @created      2023-11-2
    * @param        p_id_user           la clé primaire de l'utilisateur qu'on veut update   
    * @param        p_nom               le nom de l'utilisateur 
    * @param        p_email             l'email de l'utilisateur
    * @param        p_password          le mot de passe de l'utilisateur
    * @return       l_reponse           objet JSON avec un status et la clé primaire id_cours du cours créée
    * @exception    ex_id_is_null       si le paramètre p_id_user est null, retourne dans un objet JSON avec status et code d erreur -1
    * @exception    OTHERS              excepttion autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
    */
    FUNCTION upd_utilisateur (
        p_id_user IN utilisateur.id_user%TYPE, p_nom IN utilisateur.nom%TYPE DEFAULT NULl, 
        p_password IN utilisateur.motdepasse%TYPE DEFAULT NULL, p_email IN utilisateur.email%TYPE DEFAULT NULL,
        p_test VARCHAR2 DEFAULT 'N' 
    ) RETURN VARCHAR2 IS
        l_scope              logger_logs.scope%type := gc_scope_prefix || 'upd_utilisateur';
        l_params             logger.tab_param;
        rec_utilisateur      utilisateur%rowtype;
        l_nbre_rangee        NUMBER;
        l_reponse            VARCHAR2(4000);
        l_error_mess         VARCHAR2(4000);
        l_error_code         NUMBER;
        ex_id_is_null        EXCEPTION;

    BEGIN
        logger.append_param(l_params, 'p_id_user: ', p_id_user);
        logger.append_param(l_params, 'p_nom: ', p_nom);
        logger.append_param(l_params, 'p_email:', p_email);
        logger.append_param(l_params, 'p_password: ', p_password);
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);
        IF p_id_user IS NULL THEN
            RAISE ex_id_is_null;
        END IF;

        -- afin de faire un seul update, on peuple un record avec toutes qui peuvent être mis à jour raise no_data_found si l'id est inexsistant
        SELECT ID_USER ,NOM ,EMAIL ,MOTDEPASSE  INTO rec_utilisateur
        FROM utilisateur
        WHERE id_user = p_id_user;

         UPDATE utilisateur
        SET
           nom = coalesce (p_nom, rec_utilisateur.nom),
           email = coalesce (p_email, rec_utilisateur.email),
           motdepasse = coalesce (p_password, rec_utilisateur.motdepasse)
        WHERE
            id_user = p_id_user;

        l_nbre_rangee := sql%rowcount;
        logger.append_param(l_params, 'sql%l_nbre_rangee: ', l_nbre_rangee);
        logger.log('>>>FIN de la procédure', l_scope, NULL, l_params);
        IF p_test = 'N' THEN
            COMMIT;
        END IF;
        --creation d un objet JSON avec le status et l'utilisateur maj en format JSON:API
        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'utilisateur',
                'id'         VALUE p_id_user,
                'attributes' VALUE JSON_OBJECT(
                    'nom'              VALUE p_nom,
                    'email'            VALUE p_email,
                    'motDePasse'       VALUE p_password
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
            -- pas d utilisation de SQLERRM et SQLCODE car on a une exception personnalisée
            ROLLBACK;
            logger.log_error('>>>ERREUR de de type ex_id_is_null la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID de lutilisateur requis',
                        'detail'  VALUE 'Erreur id est null lors de la maj de lutilisateur',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
        WHEN no_data_found THEN
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            ROLLBACK;
            logger.log_error('>>>ERREUR de de type ex_id_inexistant la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Utilisateur non trouvé',
                        'detail'  VALUE 'Erreur id inexistant '|| p_id_user || ' lors de la maj de lutilisateur',
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
            logger.log_error('>>>ERREUR de de type OTHERS la procédure', l_scope, null, l_params);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la mise à jour de lutlisateur',
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END upd_utilisateur;

     /**
    * Description   fonction pour insérer un utilisateur
    *
    * @version      2.1.0               refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
    *
    * @example      l_resultant := utlisateur_tapi.ins_utlisateur ('Jean-Michel LaRoche', 'email@gmail.com', 'motDePasse1234');
    *
    * @issue        problème xyz
    *
    * @author       JF Brodeur/ Modification par Samuel Geoffroy
    * @created      2023-11-2
    * @param        p_nom               Nom et Prénom du nouvel utilisateur
    * @param        p_email             l'email de l'utilisateur NULL par défault 
    * @param        p_password          le mot de passe de l'utilisateur
    * @param        p_test              paramètre pour ne pas sauvegarder les tests, si 'N' alors commit 'N' par Default
    * @return       l_reponse           objet JSON avec un status et la clé primaire id_cours du cours créée
    * @exception    ex_params_obli_null  si le nom ou le mot de passe est null, retourné dans un objet JSON avec status et code d erreur -1400
    * @exception    OTHERS              excepttion autre non traitée, retourné dans un objet JSON avec status et code d erreur -999
    */
    FUNCTION ins_utilisateur (
        p_nom IN utilisateur.nom%TYPE, p_password IN utilisateur.motdepasse%TYPE, 
        p_email IN utilisateur.email%TYPE DEFAULT NULL, p_test VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 AS
        -- variable pour journaliser (logger) afin de peupler la colonne scope avec package + fonction de logger_logs
        l_scope           logger_logs.scope%type := gc_scope_prefix || 'ins_utilisateur';
        -- variable pour logger afin de peupler la colonne des paramètres (param) de logger_logs
        l_params          logger.tab_param;
        l_id_user        utilisateur.id_user%type;
        l_reponse         VARCHAR2(4000);
        l_error_mess      VARCHAR2(4000);
        l_error_code      NUMBER;
        ex_params_obli_null EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_params_obli_null, -1400);
    BEGIN
        -- affectation de tous les paramètres passés à la fonction pour aider au débuggage
        logger.append_param(l_params, 'p_nom: ',p_nom);
        logger.append_param(l_params, 'p_password: ', p_password);
        logger.append_param(l_params, 'p_email: ', p_email);
        logger.append_param(l_params, 'p_test: ', p_test);
        -- écriture de tous les paramètres dans le journal (logger) 
        logger.log('>>>DÉBUT de la procédure', l_scope, NULL, l_params);
        INSERT INTO utilisateur (nom , motdepasse, email) 
        VALUES (p_nom, p_password, p_email)
        RETURNING id_user INTO l_id_user;
        logger.append_param(l_params, 'l_id_user: ', l_id_user);
        IF p_test = 'N' THEN
            COMMIT;
        END IF;
        --creation d un objet JSON avec le status et l_id_user inséré
        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
            'type'       VALUE 'utilisateur',
            'id'         VALUE l_id_user,
            'attributes' VALUE JSON_OBJECT(
                'nom'              VALUE p_nom,
                'motDePasse'       VALUE p_password,
                'email'            VALUE p_email
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
        -- Dans ce bloc d exception le traitement de l erreur est fait dans le bloc d exception et non dans la partie js
        WHEN ex_params_obli_null THEN
            -- sqlerrm et sqlcode sont des fonctions qui doivent être obligatoirement affectées à des variables, s utilise dans le cas d execption de la BD
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_nom_cours_null', l_scope, null, l_params);
            --creation d un objet JSON avec un status et un code d erreur - https://blog.postman.com/best-practices-for-api-error-handling/
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                JSON_OBJECT(
                    'status'  VALUE '400',
                    'title'   VALUE 'Nom ou mot de passe de lutlisateur requis',
                    'detail'  VALUE 'Erreur nom ou motdepass null lors de l insertion du cours ORA-01400',
                    'code'    VALUE TO_CHAR(l_error_code),
                    'meta'    VALUE JSON_OBJECT('timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                    )
                )
                )
            );
            RETURN l_reponse;
        WHEN OTHERS THEN
            ROLLBACK;
            l_error_mess := sqlerrm;
            l_error_code := sqlcode;
            logger.log_error('>>>ERREUR de de type OTHERS', l_scope, null, l_params);
            --creation d un objet JSON avec un status et un code d erreur
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                JSON_OBJECT(
                    'status'  VALUE '500',
                    'title'   VALUE 'Erreur Système',
                    'detail'  VALUE 'Erreur OTHERS lors de l’insertion de lutilisateur',
                    'code'    VALUE TO_CHAR(l_error_code),
                    'meta'    VALUE JSON_OBJECT(
                    'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                    )
                )
                )
            );
            RETURN l_reponse;
    END ins_utilisateur;
END;
/
