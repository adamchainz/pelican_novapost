###########################################
HTML5 Drag and Drop and Javascript File API
###########################################

:date: 2013-01-31 16:45
:tags: html5, file, javascript, tornadoweb
:category: Javascript
:author: Rémy Hubscher


Introduction
============

Il y a quelques jours j'ai eu envie d'améliorer un peu `0bin
<http://0bin.net/>`_ afin que l'on puisse aussi partager des images en
plus du code.

Le bouton upload existant utilisait déjà l'API de fichiers javascript
et j'ai simplement eu à vérifier le mimetype et à ajouter le drag and
drop.


La File API de Javascript
=========================

Il est à noter que cette API fonctionne sur les navigateurs récents.

Il existe une solution qui permet de gérer des fallbacks pour les
autres navigateurs : `Plupload <http://www.plupload.com/>`_


Comment ça fonctionne ?
=======================

Lors d'un drag and drop, le navigateur va envoyer un event à
différents moments de l'opération.

Ces events vont nous permettre de jouer sur notre IHM pour donner du
feedback à l'utilisateur.

Voici les events qui nous intéressent:

 - **dragenter** : On amène quelque chose dans la zone
 - **dragover** : On se déplace sur la zone
 - **drop** : On dépose quelque chose dans la zone
 - **dragleave** : On quitte la zone survolée

Pour chacun de ces events, le navigateur possède un comportement par
défaut, souvent on souhaite ne pas que le fonctionnement par défaut du
navigateur s'exécute, on va donc utiliser ``stopPropagation()`` et
``preventDefault()``.


On va utiliser jQuery pour gérer tout ça::

    $('#file-drop-zone').bind('drop', handleDrop);
    $('#file-drop-zone').bind('dragover', handleDragOver);
    $('#file-drop-zone').bind('dragleave', handleDragLeave);


Et voici les fonctions que l'on souhaite utiliser::

    var handleDrop = function (e) {
      e.originalEvent.stopPropagation();
      e.originalEvent.preventDefault();
      processFiles(e.originalEvent.dataTransfer.files);
      $(this).removeClass('hover');
    };

    var handleDragOver = function (e) {
      e.originalEvent.stopPropagation();
      e.originalEvent.preventDefault();
      $(this).addClass('hover');
    };

    var handleDragLeave = function (e) {
      $(this).removeClass('hover');
    };

``e`` est l'event de jQuery et ``e.originalEvent`` celui de
javascript.


Gérer l'upload des fichiers
===========================

Il est possible de faire un drag and drop de plusieurs fichiers
simultanéments, dans ce cas il faut les gérer un à un et préparer une
barre de progression globale::

    var list = [];
    var totalSize = 0;
    var totalProgress = 0;

    var processFiles = function (filelist) {
        if (!filelist || !filelist.length || list.length) return;
        totalSize = 0;
        totalProgress = 0;
    
        for (var i = 0; i < filelist.length && i < 5; i++) {
            list.push(filelist[i]);
            totalSize += filelist[i].size;
        }
        uploadNext();
    };
    
    var uploadNext = function() {
        if (list.length) {
            $('#file-drop-zone').addClass('uploading');
            var nextFile = list.shift();
            uploadFile(nextFile);
        } else {
            $('#file-drop-zone').removeClass();
        }
    };
    
    // upload file
    var uploadFile = function(file) {
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/upload/');
        xhr.onload = function() {
            console.log(file.filename+' uploaded');
            handleComplete(file.size);
        };
        xhr.onerror = function() {
            console.log(this.responseText);
            handleComplete(file.size);
        };
        xhr.upload.onprogress = function(event) {
            handleProgress(event);
        }
    
        var formData = new FormData();
        formData.append('myfile', file);
        xhr.send(formData);
    };
    
    var handleComplete = function(size) {
        totalProgress += size;
        console.log((totalProgress / totalSize * 100)+"%");
        this.uploadNext();
    },
    
    var handleProgress = function (event) {
        var progress = totalProgress + event.loaded;
        console.log((progress / totalSize * 100)+"%");
    };

Si vous ne souhaitez gérer qu'un seul fichier, vous pouvez simplifier
un peu en appelant directement ``uploadFile`` après avoir vérifier
qu'il y a bien un fichier dans la liste de l'event.

En effet si vous faites un drag and drop d'autre chose qu'un fichier,
il se peut qu'il n'y ai aucun fichier lié à l'event.


La page ``/upload/``
====================

C'est tout simplement une page qui gère l'upload d'un fichier avec un
``multipart/form-data`` en attendant le fichier dans la variable
``myfile`` dans notre exemple.

En tornadoweb ça donnerait ça :

.. code-block:: python

    from os.path import abspath, join, splitext
    import json
    import tornado.web

    __UPLOADS__ = abspath("medias/uploads/")

    def get_user_filename(cname):
        return '_'.join(cname.split('_')[1:])

    class UploadHandler(tornado.web.RequestHandler):
    
        def post(self):
            fileinfo = self.request.files['myfile'][0]
            fname = fileinfo['filename']
            extn = splitext(fname)
            cname = '%s_%s%s' % (str(uuid.uuid4()),
                                 slugify(extn[0]), extn[1])
            fh = open(join(__UPLOADS__, cname), 'w')
            fh.write(fileinfo['body'])
            fh.close()
            self.finish(json.dumps(dict(filename=get_user_filename(cname),
                                        url='/download/%s' % cname,
                                        size=len(fileinfo['body']))))


Conclusion
==========

Bon ben le drag'n drop d'un fichier c'est pas si compliqué que ça en
fin de compte et ça ouvre de nombreuses perspectives pour vos apps web.

Vous pourrez bientôt tester tout ça sur http://0bin.net/

La prochaine étape c'est de pouvoir coller une image dans le textarea
et que ça affiche l'image. Comme le ``CTRL+SHIFT+V`` dans GIMP.

Il y a bien un event ``paste`` mais je n'arrive pas à avoir un fichier
lié à cet event.
