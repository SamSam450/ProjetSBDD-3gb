-- Généré par Oracle SQL Developer Data Modeler 24.3.1.347.1153
--   à :        2026-09-30 14:53:04 EDT
--   site :      Oracle Database 11g
--   type :      Oracle Database 11g



-- predefined type, no DDL - MDSYS.SDO_GEOMETRY

-- predefined type, no DDL - XMLTYPE

CREATE TABLE allergène (
    id_allergène NUMBER NOT NULL,
    nom          VARCHAR2(100 CHAR) NOT NULL
);

ALTER TABLE allergène ADD CONSTRAINT allergène_pk PRIMARY KEY ( id_allergène );

CREATE TABLE allergène_produit (
    produits_id_produit    NUMBER NOT NULL,
    allergène_id_allergène NUMBER NOT NULL
);

ALTER TABLE allergène_produit ADD CONSTRAINT relation_2_pk PRIMARY KEY ( produits_id_produit,
                                                                         allergène_id_allergène );

CREATE TABLE catégorie (
    id_categorie NUMBER NOT NULL,
    nom          VARCHAR2(50 CHAR) NOT NULL
);

ALTER TABLE catégorie ADD CONSTRAINT catégorie_pk PRIMARY KEY ( id_categorie );

CREATE TABLE commande (
    id_commande         NUMBER NOT NULL,
    prix_total          NUMBER NOT NULL,
    date_création       DATE,
    date_livraison      DATE NOT NULL,
    status              VARCHAR2(50 CHAR) NOT NULL,
    utilisateur_id_user NUMBER NOT NULL
);

ALTER TABLE commande ADD CONSTRAINT commande_pk PRIMARY KEY ( id_commande );

CREATE TABLE droit (
    id_droit     NUMBER NOT NULL,
    nom          VARCHAR2(50 CHAR) NOT NULL,
    role_id_role NUMBER NOT NULL
);

ALTER TABLE droit ADD CONSTRAINT droit_pk PRIMARY KEY ( id_droit );

CREATE TABLE gateau_sur_mesure (
    id_sur_mesure       NUMBER NOT NULL,
    description         VARCHAR2(500 CHAR) NOT NULL,
    prix                NUMBER NOT NULL,
    status              VARCHAR2(100 CHAR),
    utilisateur_id_user NUMBER NOT NULL
);

ALTER TABLE gateau_sur_mesure ADD CONSTRAINT gateau_sur_mesure_pk PRIMARY KEY ( id_sur_mesure );

CREATE TABLE produit_commande (
    id_produits_commande NUMBER NOT NULL,
    qte_commande         NUMBER(2) NOT NULL,
    commande_id_commande NUMBER NOT NULL,
    produits_id_produit  NUMBER NOT NULL
);

ALTER TABLE produit_commande ADD CONSTRAINT produit_commande_pk PRIMARY KEY ( id_produits_commande );

CREATE TABLE produits (
    id_produit             NUMBER NOT NULL,
    nom                    VARCHAR2(50 CHAR) NOT NULL,
    prix                   NUMBER NOT NULL,
    qte_dispo              NUMBER,
    description            VARCHAR2(2500 CHAR),
    catégorie_id_catégorie NUMBER NOT NULL
);

ALTER TABLE produits ADD CONSTRAINT produits_pk PRIMARY KEY ( id_produit );

CREATE TABLE role (
    id_role             NUMBER NOT NULL,
    nom                 VARCHAR2(50 CHAR) NOT NULL,
    utilisateur_id_user NUMBER NOT NULL
);

ALTER TABLE role ADD CONSTRAINT role_pk PRIMARY KEY ( id_role );

CREATE TABLE "Session" (
    id_session          NUMBER NOT NULL,
    utilisateur_id_user NUMBER NOT NULL
);

ALTER TABLE "Session" ADD CONSTRAINT session_pk PRIMARY KEY ( id_session );

CREATE TABLE utilisateur (
    id_user    NUMBER NOT NULL,
    nom        VARCHAR2(75 CHAR) NOT NULL,
    email      VARCHAR2(75 CHAR),
    motdepasse VARCHAR2(75 CHAR) NOT NULL
);

ALTER TABLE utilisateur ADD CONSTRAINT utilisateur_pk PRIMARY KEY ( id_user );

ALTER TABLE commande
    ADD CONSTRAINT commande_utilisateur_fk FOREIGN KEY ( utilisateur_id_user )
        REFERENCES utilisateur ( id_user );

ALTER TABLE droit
    ADD CONSTRAINT droit_role_fk FOREIGN KEY ( role_id_role )
        REFERENCES role ( id_role );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE gateau_sur_mesure
    ADD CONSTRAINT gateau_sur_mesure_utilisateur_fk FOREIGN KEY ( utilisateur_id_user )
        REFERENCES utilisateur ( id_user );

ALTER TABLE produit_commande
    ADD CONSTRAINT produit_commande_commande_fk FOREIGN KEY ( commande_id_commande )
        REFERENCES commande ( id_commande );

ALTER TABLE produit_commande
    ADD CONSTRAINT produit_commande_produits_fk FOREIGN KEY ( produits_id_produit )
        REFERENCES produits ( id_produit );

ALTER TABLE produits
    ADD CONSTRAINT produits_catégorie_fk FOREIGN KEY ( catégorie_id_catégorie )
        REFERENCES catégorie ( id_categorie );

ALTER TABLE allergène_produit
    ADD CONSTRAINT relation_2_allergène_fk FOREIGN KEY ( allergène_id_allergène )
        REFERENCES allergène ( id_allergène );

ALTER TABLE allergène_produit
    ADD CONSTRAINT relation_2_produits_fk FOREIGN KEY ( produits_id_produit )
        REFERENCES produits ( id_produit );

ALTER TABLE role
    ADD CONSTRAINT role_utilisateur_fk FOREIGN KEY ( utilisateur_id_user )
        REFERENCES utilisateur ( id_user );

ALTER TABLE "Session"
    ADD CONSTRAINT session_utilisateur_fk FOREIGN KEY ( utilisateur_id_user )
        REFERENCES utilisateur ( id_user );

CREATE SEQUENCE allergène_id_allergène_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER allergène_id_allergène_trg BEFORE
    INSERT ON allergène
    FOR EACH ROW
    WHEN ( new.id_allergène IS NULL )
BEGIN
    :new.id_allergène := allergène_id_allergène_seq.nextval;
END;
/

CREATE SEQUENCE catégorie_id_categorie_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER catégorie_id_categorie_trg BEFORE
    INSERT ON catégorie
    FOR EACH ROW
    WHEN ( new.id_categorie IS NULL )
BEGIN
    :new.id_categorie := catégorie_id_categorie_seq.nextval;
END;
/

CREATE SEQUENCE commande_id_commande_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER commande_id_commande_trg BEFORE
    INSERT ON commande
    FOR EACH ROW
    WHEN ( new.id_commande IS NULL )
BEGIN
    :new.id_commande := commande_id_commande_seq.nextval;
END;
/

CREATE SEQUENCE droit_id_droit_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER droit_id_droit_trg BEFORE
    INSERT ON droit
    FOR EACH ROW
    WHEN ( new.id_droit IS NULL )
BEGIN
    :new.id_droit := droit_id_droit_seq.nextval;
END;
/

CREATE SEQUENCE gateau_sur_mesure_id_sur_mesur START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER gateau_sur_mesure_id_sur_mesur BEFORE
    INSERT ON gateau_sur_mesure
    FOR EACH ROW
    WHEN ( new.id_sur_mesure IS NULL )
BEGIN
    :new.id_sur_mesure := gateau_sur_mesure_id_sur_mesur.nextval;
END;
/

CREATE SEQUENCE produit_commande_id_produits_c START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER produit_commande_id_produits_c BEFORE
    INSERT ON produit_commande
    FOR EACH ROW
    WHEN ( new.id_produits_commande IS NULL )
BEGIN
    :new.id_produits_commande := produit_commande_id_produits_c.nextval;
END;
/

CREATE SEQUENCE produits_id_produit_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER produits_id_produit_trg BEFORE
    INSERT ON produits
    FOR EACH ROW
    WHEN ( new.id_produit IS NULL )
BEGIN
    :new.id_produit := produits_id_produit_seq.nextval;
END;
/

CREATE SEQUENCE role_id_role_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER role_id_role_trg BEFORE
    INSERT ON role
    FOR EACH ROW
    WHEN ( new.id_role IS NULL )
BEGIN
    :new.id_role := role_id_role_seq.nextval;
END;
/

CREATE SEQUENCE session_id_session_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER session_id_session_trg BEFORE
    INSERT ON "Session"
    FOR EACH ROW
    WHEN ( new.id_session IS NULL )
BEGIN
    :new.id_session := session_id_session_seq.nextval;
END;
/

CREATE SEQUENCE utilisateur_id_user_seq START WITH 1 NOCACHE ORDER;

CREATE OR REPLACE TRIGGER utilisateur_id_user_trg BEFORE
    INSERT ON utilisateur
    FOR EACH ROW
    WHEN ( new.id_user IS NULL )
BEGIN
    :new.id_user := utilisateur_id_user_seq.nextval;
END;
/



-- Rapport récapitulatif d'Oracle SQL Developer Data Modeler : 
-- 
-- CREATE TABLE                            11
-- CREATE INDEX                             0
-- ALTER TABLE                             21
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                          10
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                         10
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   1
-- WARNINGS                                 0
