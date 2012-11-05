########################################
JStorage - Cross Browser JS localStorage
########################################

:date: 2012-09-27 14:05
:tags: javascript, html5
:category: Javascript
:author: Rémy Hubscher

Introduction
************

La pagination c'est bien pour l'ergonomie, mais lorsqu'il s'agit de
faire des actions sur de multiples fichiers ce n'est pas forcément
évident surtout si on veut conserver la sélection d'une page à l'autre.

Mon use case est de permettre à l'utilisateur de sélectionner une
liste de fichiers puis de les télécharger d'un seul clic.


Pourquoi utiliser les cookies n'est pas une bonne solution ?
************************************************************

Certaines personnes seraient tentées de stocker ces informations dans
un cookie, le problème c'est que les informations sont alors envoyées
à chaque requête au serveur, de plus la taille maximale d'un cookie
est limitée à 4KB ce qui peut être limitant.

Dans ce cas précis, nous souhaitons simplement garder des informations
dans notre navigateur pour modifier l'IHM à la volée et savoir envoyer
la liste des documents lors du clic sur une action.


JStorage, une solution cross-framework et cross-browser
*******************************************************

La solution que j'ai trouvé, c'est d'utiliser JStorage_.

Ça ressemble à ce qu'on pourrait faire avec redis, sauf que c'est côté
navigateur de l'utilisateur.

Un des gros avantages, c'est qu'il est possible de l'utiliser avec
jQuery_, Prototype_ ou MooTools_ avec `la même API`_.

.. _JStorage: http://www.jstorage.info/
.. _jQuery: http://jquery.com/
.. _Prototype: http://prototypejs.org/
.. _MooTools: http://mootools.net/
.. _`la même API`: http://www.jstorage.info/test


Gérer une liste persistante d'éléments entre les pages
******************************************************

Après avoir inclus les bibliothèques qui nous intéressent :

.. code-block:: html
    
    <script type="text/javascript" src="{% static 'js/jquery.last.min.js' %}"></script>
    <script type="text/javascript" src="{% static 'js/jquery.json-2.3.min.js' %}"></script>
    <script type="text/javascript" src="{% static 'js/jstorage.min.js' %}"></script>


Nous pouvons gérer notre liste d'éléments de la manière suivante : 

.. code-block:: javascript

    // Récupérer la liste d'éléments
    function get_list() {
       return $.jStorage.get("document_list", []);
    }

    // Set the list and reset the TTL
    function set_list(l) {
        $.jStorage.set("document_list", l);
        $.jStorage.setTTL("document_list", 10*60*1000); //Time-to-live de 10 minutes
    }
    
    // Ajouter un élément à la liste
    function add_to_list(value) {
        var l = get_list();
        l.push(value);
        set_list(l);
        return l;
    }
    
    // Supprimer un élément de la liste
    function del_from_list(value) {
        var l = get_list();
        var idx = l.indexOf(value);
        if (idx != -1) l.splice(idx, 1);
        set_list(l);
        return l;
    }
    
    // Réinitialiser la liste
    function reset_list(value) {
        set_list([]);
        refresh_checkboxes();
    }
    
    // Compter le nombre d'éléments dans la liste
    function count_list() {
        var l = get_list();
        return l.length;
    }
    
    // Sélectionner tous les documents de la page
    function toggle_all() {
        var status = $('#document_actions input[name$="document"]').first().is(':checked');
        $('#document_actions input[name$="document"]').each(function () {
            if($(this).is(':checked') == status) {
                $(this).attr("checked", !status); // Trick to have the click callback to work
                $(this).click();
                $(this).attr("checked", !status); // Trick to have the click callback to work              
            }
        });
        $("#toggle_docs").attr("checked", !status);
    }
    
    // Mettre à jour l'affichage des boutons d'actions
    function refresh_counter() {
        if (count_list() == 0) {
            $("#download").hide();
            $("#reset_file_selection").hide();
        } else {
            $("#download").show();
            $("#reset_file_selection").show();
        }
        $(".file_counter").html(" ("+count_list()+")")
    }
    
    // Mettre à jour le status des checkbox à partir du localStorage
    function refresh_checkboxes() {
        refresh_counter();
        var all_on_page = true
        $('#document_actions input[name$="document"]').each(function () {
            var l = get_list();
            var idx = l.indexOf($(this).val());
            if (idx != -1) $(this).click();
            else {
                if($(this).is(':checked')) $(this).removeAttr("checked");
                all_on_page = false;
            }
        });
        $("#toggle_docs").attr("checked", all_on_page);
    }
    
    // Préparer le formulaire d'upload lors du submit
    function prepare_submit(e) {
        var l = get_list();
        reset_list();
        for(var e in l) {
            var checkbox = document.createElement('input');
            checkbox.type = "checkbox";
            checkbox.name = "document";
            checkbox.value = l[e];
            $(checkbox).hide();
            $(checkbox).attr("checked", true);
            $("#document_actions").append(checkbox);
        }
        return true
    }
    
    // Connecter les signaux javascripts aux bons callbacks
    $(document).ready(function() {
        refresh_checkboxes();
        $('#document_actions input[name$="document"]').click(function() {
            if($(this).is(':checked')) {
                add_to_list($(this).val());
                if($('#document_actions input[name$="document"]:not(:checked)').size() == 0) 
                    $("#toggle_docs").attr("checked", "checked");
            } else {
                del_from_list($(this).val());
                $("#toggle_docs").removeAttr("checked");
            }
            refresh_counter();
        });
        $('#document_actions').submit(prepare_submit);
    });

Ceci naturellement nécessite d'avoir les bons id dans le code HTML :

.. code-block:: html

    <form method="post" action="{% url 'document_actions' %}" id="document_actions">
        <div class="row-fluid">
            <div class="span1 center">
                <input type="checkbox" id="toggle_docs" onclick="toggle_all();">
            </div>
            <div class="span11">
                <button type="submit" id="download" name="action" value="download" class="btn btn-primary">
                    {% trans "Download" %}<span class="file_counter"></span>
                </button>
                <button type="button" id="reset_file_selection" onclick="reset_list();" class="btn btn-info">
                    {% trans "Reset file selection" %}
                </button>
            </div>
        </div>

        <ul>
          {% for document in object_list %}
          <li><input type="checkbox" name="document" value="{{ document.uuid }}" /> {{ document.name }}</li>
          {% endfor %}
        </ul>
    </form>

Conclusion
**********

 * Ici on choisit de réinitialiser le local storage lors d'une action
   d'où le ``reset_list`` dans ``prepare_submit``.
 * On peut passer d'une page à l'autre en conservant cette liste et en
   la complétant, ça permet notamment d'ajouter des documents issus de
   la page de recherche.
 * La clé dans le local storage n'expire jamais même après fermeture
   du navigateur. Ici on utilise `la méthode setTTL`_ que l'on
   configure à 10 minutes pour éviter que lorsque l'utilisateur
   revienne il se retrouve avec une selection inattendue.

Lien connexes
*************

 * Github de JStorage : https://github.com/andris9/jStorage
 * Voir aussi le projet HTML5-Local-Redis : https://github.com/mrjoelkemp/html5-local-redis

.. _`la méthode setTTL`: http://www.jstorage.info/#reference
