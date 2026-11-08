CREATE OR REPLACE PACKAGE COMMANDE_tapi IS

   TYPE commande_tapi_rec IS RECORD (
      id_commande         commande.id_commande%TYPE,
      prix_total          commande.prix_total%TYPE,
      date_création       commande.date_création%TYPE,
      date_livraison      commande.date_livraison%TYPE,
      status              commande.status%TYPE,
      utilisateur_id_user commande.utilisateur_id_user%TYPE
   );

   TYPE commande_tapi_tab IS TABLE OF commande_tapi_rec;

   -- Insertion (Create)
   FUNCTION ins (
      p_prix_total          IN commande.prix_total%TYPE,
      p_date_livraison      IN commande.date_livraison%TYPE,
      p_status              IN commande.status%TYPE,
      p_utilisateur_id_user IN commande.utilisateur_id_user%TYPE,
      p_date_création       IN commande.date_création%TYPE DEFAULT NULL,
      p_test                IN VARCHAR2 DEFAULT 'N'
   ) RETURN VARCHAR2;

   -- Sélection (Read / Get)
   FUNCTION sel (
      p_id_commande IN commande.id_commande%TYPE
   ) RETURN VARCHAR2;

   -- Mise à jour (Update)
   FUNCTION upd (
      p_id_commande         IN commande.id_commande%TYPE,
      p_prix_total          IN commande.prix_total%TYPE DEFAULT NULL,
      p_date_livraison      IN commande.date_livraison%TYPE DEFAULT NULL,
      p_status              IN commande.status%TYPE DEFAULT NULL,
      p_utilisateur_id_user IN commande.utilisateur_id_user%TYPE DEFAULT NULL,
      p_date_création       IN commande.date_création%TYPE DEFAULT NULL,
      p_test                IN VARCHAR2 DEFAULT 'N'
   ) RETURN VARCHAR2;

   -- Suppression (Delete)
   FUNCTION del (
      p_id_commande IN commande.id_commande%TYPE,
      p_test        IN VARCHAR2 DEFAULT 'N'
   ) RETURN VARCHAR2;

END COMMANDE_tapi;

/


CREATE OR REPLACE PACKAGE BODY COMMANDE_tapi IS

    gc_scope_prefix CONSTANT VARCHAR2(31) := lower($$plsql_unit) || '.';

    /**
     * Description   Fonction pour insérer une commande dans la table COMMANDE
     *
     * @version      2.1.0               Refonte pour traiter les exceptions en tableau JSON et ajout de status et format JSON:API
     *
     * @example      l_reponse := COMMANDE_tapi.ins(45.50, SYSDATE + 5, 'EN_COURS', 1, SYSDATE, 'N');
     *
     * @issue        n/a
     *
     * @author       Dragomir Georgiev
     * @created      2026-11-05
     * @param        p_prix_total          Prix total de la commande
     * @param        p_date_livraison      Date prévue pour la livraison
     * @param        p_status              Statut de la commande (ex. EN_COURS, LIVRÉE, ANNULÉE)
     * @param        p_utilisateur_id_user Clé étrangère de l'utilisateur rattaché
     * @param        p_date_création       Date de création de la commande (optionnel, SYSDATE par défaut)
     * @param        p_test                Paramètre de test ('O' pour ne pas sauvegarder, 'N' pour commit)
     * @return       l_reponse             Objet JSON au format JSON:API avec status et ID généré
     * @exception    ex_valeur_nulle       Si une colonne obligatoire est null, code d'erreur ORA-01400 (400 Bad Request)
     * @exception    OTHERS                Exception non traitée, retournée en objet JSON avec code système (500)
     */
    FUNCTION ins (
        p_prix_total          IN commande.prix_total%TYPE,
        p_date_livraison      IN commande.date_livraison%TYPE,
        p_status              IN commande.status%TYPE,
        p_utilisateur_id_user IN commande.utilisateur_id_user%TYPE,
        p_date_création       IN commande.date_création%TYPE DEFAULT NULL,
        p_test                IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope         VARCHAR2(61) := gc_scope_prefix || 'ins';
        l_id_commande   commande.id_commande%TYPE;
        l_date_creation DATE := coalesce(p_date_création, SYSDATE);
        l_reponse       VARCHAR2(4000);
        l_error_mess    VARCHAR2(4000);
        l_error_code    NUMBER;
        ex_valeur_nulle EXCEPTION;
        PRAGMA EXCEPTION_INIT(ex_valeur_nulle, -1400);
    BEGIN
        logger.log('>>>DÉBUT de l''insertion', l_scope);

        INSERT INTO commande (
            prix_total,
            date_création,
            date_livraison,
            status,
            utilisateur_id_user
        ) VALUES (
            p_prix_total,
            l_date_creation,
            p_date_livraison,
            p_status,
            p_utilisateur_id_user
        ) RETURNING id_commande INTO l_id_commande;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'commande',
                'id'         VALUE l_id_commande,
                'attributes' VALUE JSON_OBJECT(
                    'prixTotal'         VALUE p_prix_total,
                    'dateCreation'      VALUE TO_CHAR(l_date_creation, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'dateLivraison'     VALUE TO_CHAR(p_date_livraison, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'status'            VALUE p_status,
                    'utilisateurIdUser' VALUE p_utilisateur_id_user
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 201
            )
        );

        logger.log('>>>FIN de l''insertion', l_scope);
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_valeur_nulle THEN
            ROLLBACK;
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type ex_valeur_nulle', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'Champs obligatoires manquants',
                        'detail'  VALUE 'Erreur colonne obligatoire NULL lors de l''insertion ORA-01400',
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
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de l''insertion : ' || l_error_mess,
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END ins;

    /**
     * Description   Fonction pour récupérer une commande à partir de son identifiant
     *
     * @version      2.1.0               Refonte pour traiter les exceptions en tableau JSON et format JSON:API
     *
     * @example      l_reponse := COMMANDE_tapi.sel(1);
     *
     * @issue        n/a
     *
     * @author       Dragomir Georgiev
     * @created      2026-11-05
     * @param        p_id_commande       Clé primaire de la commande à consulter
     * @return       l_reponse           Objet JSON contenant les détails de la commande ou un tableau d'erreurs
     * @exception    ex_aucune_commande  Si l'identifiant est introuvable, code d'erreur -20001 (404 Not Found)
     * @exception    OTHERS              Exception non traitée, retournée en objet JSON avec code système (500)
     */
    FUNCTION sel (
        p_id_commande IN commande.id_commande%TYPE
    ) RETURN VARCHAR2 IS
        l_scope              VARCHAR2(61) := gc_scope_prefix || 'sel';
        r_commande           commande%ROWTYPE;
        l_reponse            VARCHAR2(4000);
        l_error_mess         VARCHAR2(4000);
        l_error_code         NUMBER;
        ex_aucune_commande   EXCEPTION;
    BEGIN
        logger.log('>>>DÉBUT de la sélection', l_scope);

        IF p_id_commande IS NULL THEN
            RAISE ex_aucune_commande;
        END IF;

        BEGIN
            SELECT *
              INTO r_commande
              FROM commande
             WHERE id_commande = p_id_commande;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE ex_aucune_commande;
        END;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'commande',
                'id'         VALUE r_commande.id_commande,
                'attributes' VALUE JSON_OBJECT(
                    'prixTotal'         VALUE r_commande.prix_total,
                    'dateCreation'      VALUE TO_CHAR(r_commande.date_création, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'dateLivraison'     VALUE TO_CHAR(r_commande.date_livraison, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'status'            VALUE r_commande.status,
                    'utilisateurIdUser' VALUE r_commande.utilisateur_id_user
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );

        logger.log('>>>FIN de la sélection', l_scope);
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_aucune_commande THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_aucune_commande', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '404',
                        'title'   VALUE 'Commande non trouvée',
                        'detail'  VALUE 'Aucune commande trouvée pour l''ID ' || p_id_commande,
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
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la sélection : ' || l_error_mess,
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END sel;

    /**
     * Description   Fonction pour mettre à jour une commande existante
     *
     * @version      2.1.0               Refonte pour traiter les exceptions en tableau JSON et format JSON:API
     *
     * @example      l_reponse := COMMANDE_tapi.upd(1, 120.00, NULL, 'LIVRÉE', NULL, NULL, 'N');
     *
     * @issue        n/a
     *
     * @author       Dragomir Georgiev
     * @created      2026-11-05
     * @param        p_id_commande         Clé primaire de la commande à modifier
     * @param        p_prix_total          Nouveau montant (optionnel, conserve la valeur actuelle si null)
     * @param        p_date_livraison      Nouvelle date de livraison (optionnel, conserve la valeur actuelle si null)
     * @param        p_status              Nouveau statut (optionnel, conserve la valeur actuelle si null)
     * @param        p_utilisateur_id_user Nouveau propriétaire (optionnel, conserve la valeur actuelle si null)
     * @param        p_date_création       Nouvelle date de création (optionnel, conserve la valeur actuelle si null)
     * @param        p_test                Paramètre de test ('O' pour ne pas sauvegarder, 'N' pour commit)
     * @return       l_reponse             Objet JSON confirmant la modification effectuée
     * @exception    ex_id_is_null         Si p_id_commande est null, code d'erreur -1 (400 Bad Request)
     * @exception    ex_id_inexistant      Si aucun enregistrement ne correspond à l'ID, code d'erreur -2 (404 Not Found)
     * @exception    OTHERS                Exception non traitée, retournée en objet JSON avec code système (500)
     */
    FUNCTION upd (
        p_id_commande         IN commande.id_commande%TYPE,
        p_prix_total          IN commande.prix_total%TYPE DEFAULT NULL,
        p_date_livraison      IN commande.date_livraison%TYPE DEFAULT NULL,
        p_status              IN commande.status%TYPE DEFAULT NULL,
        p_utilisateur_id_user IN commande.utilisateur_id_user%TYPE DEFAULT NULL,
        p_date_création       IN commande.date_création%TYPE DEFAULT NULL,
        p_test                IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope          VARCHAR2(61) := gc_scope_prefix || 'upd';
        r_commande       commande%ROWTYPE;
        l_reponse        VARCHAR2(4000);
        l_error_mess     VARCHAR2(4000);
        l_error_code     NUMBER;
        ex_id_is_null    EXCEPTION;
        ex_id_inexistant EXCEPTION;
    BEGIN
        logger.log('>>>DÉBUT de la mise à jour', l_scope);

        IF p_id_commande IS NULL THEN
            RAISE ex_id_is_null;
        END IF;

        BEGIN
            SELECT * INTO r_commande
              FROM commande
             WHERE id_commande = p_id_commande;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE ex_id_inexistant;
        END;

        UPDATE commande
           SET prix_total          = coalesce(p_prix_total, r_commande.prix_total),
               date_création       = coalesce(p_date_création, r_commande.date_création),
               date_livraison      = coalesce(p_date_livraison, r_commande.date_livraison),
               status              = coalesce(p_status, r_commande.status),
               utilisateur_id_user = coalesce(p_utilisateur_id_user, r_commande.utilisateur_id_user)
         WHERE id_commande = p_id_commande;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type'       VALUE 'commande',
                'id'         VALUE p_id_commande,
                'attributes' VALUE JSON_OBJECT(
                    'prixTotal'         VALUE coalesce(p_prix_total, r_commande.prix_total),
                    'dateCreation'      VALUE TO_CHAR(coalesce(p_date_création, r_commande.date_création), 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'dateLivraison'     VALUE TO_CHAR(coalesce(p_date_livraison, r_commande.date_livraison), 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'status'            VALUE coalesce(p_status, r_commande.status),
                    'utilisateurIdUser' VALUE coalesce(p_utilisateur_id_user, r_commande.utilisateur_id_user)
                )
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );

        logger.log('>>>FIN de la mise à jour', l_scope);
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID de commande requis',
                        'detail'  VALUE 'Erreur : l''ID de la commande ne peut pas être null lors de la mise à jour',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
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
                        'title'   VALUE 'Commande non trouvée',
                        'detail'  VALUE 'Aucune commande existante avec l''ID ' || p_id_commande,
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
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la mise à jour : ' || l_error_mess,
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END upd;

    /**
     * Description   Fonction pour effacer une commande de la table COMMANDE
     *
     * @version      2.1.0               Refonte pour traiter les exceptions en tableau JSON et format JSON:API
     *
     * @example      l_reponse := COMMANDE_tapi.del(1, 'N');
     *
     * @issue        n/a
     *
     * @author       Dragomir Georgiev
     * @created      2026-11-05
     * @param        p_id_commande       Clé primaire de la commande à supprimer
     * @param        p_test              Paramètre de test ('O' pour ne pas sauvegarder, 'N' pour commit)
     * @return       l_reponse           Objet JSON confirmant l'effacement de la commande
     * @exception    ex_id_is_null       Si p_id_commande est null, code d'erreur -1 (400 Bad Request)
     * @exception    ex_id_inexistant    Si l'enregistrement n'existe pas, code d'erreur -2 (404 Not Found)
     * @exception    OTHERS              Exception non traitée, retournée en objet JSON avec code système (500)
     */
    FUNCTION del (
        p_id_commande IN commande.id_commande%TYPE,
        p_test        IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_scope          VARCHAR2(61) := gc_scope_prefix || 'del';
        l_nbre_rangee    NUMBER;
        l_reponse        VARCHAR2(4000);
        l_error_mess     VARCHAR2(4000);
        l_error_code     NUMBER;
        ex_id_is_null    EXCEPTION;
        ex_id_inexistant EXCEPTION;
    BEGIN
        logger.log('>>>DÉBUT de la suppression', l_scope);

        IF p_id_commande IS NULL THEN
            RAISE ex_id_is_null;
        END IF;

        DELETE FROM commande
         WHERE id_commande = p_id_commande;

        l_nbre_rangee := SQL%ROWCOUNT;

        IF l_nbre_rangee = 0 THEN
            RAISE ex_id_inexistant;
        END IF;

        IF p_test = 'N' THEN
            COMMIT;
        END IF;

        l_reponse := JSON_OBJECT(
            'data' VALUE JSON_OBJECT(
                'type' VALUE 'commande',
                'id'   VALUE p_id_commande
            ),
            'meta' VALUE JSON_OBJECT(
                'status'     VALUE 'success',
                'statusCode' VALUE 200
            )
        );

        logger.log('>>>FIN de la suppression', l_scope);
        RETURN l_reponse;

    EXCEPTION
        WHEN ex_id_is_null THEN
            ROLLBACK;
            logger.log_error('>>>ERREUR de type ex_id_is_null', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '400',
                        'title'   VALUE 'ID de commande requis',
                        'detail'  VALUE 'Erreur : l''ID de la commande est obligatoire pour la suppression',
                        'code'    VALUE TO_CHAR(-1),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
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
                        'title'   VALUE 'Commande non trouvée',
                        'detail'  VALUE 'Erreur : ID inexistant ' || p_id_commande || ' lors de la suppression',
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
            l_error_mess := SQLERRM;
            l_error_code := SQLCODE;
            logger.log_error('>>>ERREUR de type OTHERS', l_scope);
            l_reponse := JSON_OBJECT(
                'errors' VALUE JSON_ARRAY(
                    JSON_OBJECT(
                        'status'  VALUE '500',
                        'title'   VALUE 'Erreur système',
                        'detail'  VALUE 'Erreur OTHERS lors de la suppression : ' || l_error_mess,
                        'code'    VALUE TO_CHAR(l_error_code),
                        'meta'    VALUE JSON_OBJECT(
                            'timestamp' VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS')
                        )
                    )
                )
            );
            RETURN l_reponse;
    END del;

END COMMANDE_tapi;

/
