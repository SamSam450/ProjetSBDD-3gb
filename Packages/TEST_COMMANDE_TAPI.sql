CREATE OR REPLACE package test_commande_tapi
is
   --%suite(Tests unitaires de COMMANDE_tapi)
   --%suitepath(all.commande)

   --%test(Test insertion et sélection d'une commande)
   procedure test_ins_sel;

   --%test(Test mise à jour d'une commande)
   procedure test_upd;

   --%test(Test suppression d'une commande)
   procedure test_del;

   --%test(Test de lecture d'une commande inexistante)
   procedure test_sel_non_trouve;

end test_commande_tapi;

/


CREATE OR REPLACE package body test_commande_tapi
is
   --Dragomir Georgiev
   -- Fonction utilitaire interne pour trouver un utilisateur valide
   function get_valid_user_id return commande.utilisateur_id_user%type is
      l_user_id commande.utilisateur_id_user%type;
   begin
      select id_user 
        into l_user_id 
        from utilisateur 
       where rownum = 1;
      return l_user_id;
   exception
      when no_data_found then
         raise_application_error(-20010, 'Aucun utilisateur trouvé en base pour exécuter les tests de commande.');
   end get_valid_user_id;

   -- -------------------------------------------------------------------------
   -- Test Insertion et Lecture
   -- -------------------------------------------------------------------------
   procedure test_ins_sel is
      l_user_id   commande.utilisateur_id_user%type;
      l_json_ins  varchar2(4000);
      l_json_sel  varchar2(4000);
      l_id_com    commande.id_commande%type;
      l_prix      number;
      l_status    varchar2(50);
   begin
      l_user_id := get_valid_user_id;

      -- 1. Insertion (p_test => 'O' pour ne pas committer en base)
      l_json_ins := commande_tapi.ins(
         p_prix_total          => 45.50,
         p_date_livraison      => sysdate + 5,
         p_status              => 'EN_COURS',
         p_utilisateur_id_user => l_user_id,
         p_test                => 'O'
      );

      l_id_com := to_number(json_value(l_json_ins, '$.data.id'));

      if l_id_com is null or l_id_com <= 0 then
         raise_application_error(-20001, 'ÉCHEC test_ins_sel : L''ID retourné est invalide. Réponse : ' || l_json_ins);
      end if;

      -- 2. Lecture / Sélection
      l_json_sel := commande_tapi.sel(l_id_com);
      l_prix     := to_number(json_value(l_json_sel, '$.data.attributes.prixTotal'));
      l_status   := json_value(l_json_sel, '$.data.attributes.status');

      if l_prix != 45.50 or l_status != 'EN_COURS' then
         raise_application_error(-20002, 'ÉCHEC test_ins_sel : Données lues incorrectes. Réponse : ' || l_json_sel);
      end if;

      rollback;
   exception
      when others then
         rollback;
         raise;
   end test_ins_sel;

   -- -------------------------------------------------------------------------
   -- Test Mise à jour
   -- -------------------------------------------------------------------------
   procedure test_upd is
      l_user_id   commande.utilisateur_id_user%type;
      l_json_ins  varchar2(4000);
      l_json_upd  varchar2(4000);
      l_id_com    commande.id_commande%type;
      l_prix_maj  number;
      l_stat_maj  varchar2(50);
   begin
      l_user_id := get_valid_user_id;

      -- Insertion initiale
      l_json_ins := commande_tapi.ins(
         p_prix_total          => 100.00,
         p_date_livraison      => sysdate + 2,
         p_status              => 'EN_COURS',
         p_utilisateur_id_user => l_user_id,
         p_test                => 'O'
      );
      l_id_com := to_number(json_value(l_json_ins, '$.data.id'));

      -- Mise à jour
      l_json_upd := commande_tapi.upd(
         p_id_commande         => l_id_com,
         p_prix_total          => 120.00,
         p_status              => 'LIVRÉE',
         p_test                => 'O'
      );

      l_prix_maj := to_number(json_value(l_json_upd, '$.data.attributes.prixTotal'));
      l_stat_maj := json_value(l_json_upd, '$.data.attributes.status');

      if l_prix_maj != 120.00 or l_stat_maj != 'LIVRÉE' then
         raise_application_error(-20003, 'ÉCHEC test_upd : Valeurs modifiées incorrectes. Réponse : ' || l_json_upd);
      end if;

      rollback;
   exception
      when others then
         rollback;
         raise;
   end test_upd;

   -- -------------------------------------------------------------------------
   -- Test Suppression
   -- -------------------------------------------------------------------------
   procedure test_del is
      l_user_id     commande.utilisateur_id_user%type;
      l_json_ins    varchar2(4000);
      l_json_del    varchar2(4000);
      l_json_sel    varchar2(4000);
      l_id_com      commande.id_commande%type;
      l_status_code varchar2(20);
   begin
      l_user_id := get_valid_user_id;

      -- Insertion
      l_json_ins := commande_tapi.ins(
         p_prix_total          => 25.00,
         p_date_livraison      => sysdate + 1,
         p_status              => 'ANNULÉE',
         p_utilisateur_id_user => l_user_id,
         p_test                => 'O'
      );
      l_id_com := to_number(json_value(l_json_ins, '$.data.id'));

      -- Suppression
      l_json_del := commande_tapi.del(
         p_id_commande => l_id_com,
         p_test        => 'O'
      );

      if json_value(l_json_del, '$.meta.status') != 'success' then
         raise_application_error(-20004, 'ÉCHEC test_del : La suppression a échoué. Réponse : ' || l_json_del);
      end if;

      -- Vérification que l'enregistrement renvoie bien l'erreur JSON 404
      l_json_sel    := commande_tapi.sel(l_id_com);
      l_status_code := json_value(l_json_sel, '$.errors[0].status');

      if l_status_code != '404' then
         raise_application_error(-20005, 'ÉCHEC test_del : La commande existe toujours après suppression.');
      end if;

      rollback;
   exception
      when others then
         rollback;
         raise;
   end test_del;

   -- -------------------------------------------------------------------------
   -- Test Sélection Inexistante (Erreur 404 attendue)
   -- -------------------------------------------------------------------------
   procedure test_sel_non_trouve is
      l_json_sel   varchar2(4000);
      l_status     varchar2(10);
      l_error_code varchar2(20);
   begin
      l_json_sel   := commande_tapi.sel(-99999);
      l_status     := json_value(l_json_sel, '$.errors[0].status');
      l_error_code := json_value(l_json_sel, '$.errors[0].code');

      if l_status != '404' or l_error_code != '-20001' then
         raise_application_error(-20006, 'ÉCHEC test_sel_non_trouve : Erreur 404 (-20001) attendue. Réponse : ' || l_json_sel);
      end if;
   end test_sel_non_trouve;

end test_commande_tapi;
/
