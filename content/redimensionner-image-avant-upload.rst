###################################################
Redimensionner une image côté client avant l'upload
###################################################

:date: 2013-01-31 17:54
:tags: html5, file, javascript
:category: Javascript
:author: Rémy Hubscher


Introduction
============

Il y a quelques jours j'ai eu envie d'améliorer un peu `0bin
<http://0bin.net/>`_ afin qu'on puisse aussi partager des images en
plus du code.

Et pour éviter que les gens voit une erreur "votre fichier est trop
volumineux", j'ai eu envie de les redimensionner côté client avant
l'upload.


Comment faire ?
===============

En fait depuis peu, les navigateurs récent possèdent une balise HTML5
canvas que l'on peut utiliser comme un outil de traitement d'images.

La solution consiste à charger l'image dans un ``objet Image``
Javascript, puis de la dessiner redimensionnée dans un canvas. On
récupère ensuite la donnée depuis le canvas et on créé un ``objet
Blob`` qu'on utilise ensuite pour faire l'upload.

Voici comment on utilise le canvas pour redimensionner l'image :

.. code-block:: javascript

      var current_file = files[0];
      var reader = new FileReader();
      if (current_file.type.indexOf('image') == 0) {
        reader.onload = function (event) {
            var image = new Image();
            image.src = event.target.result;

            image.onload = function() {
              var maxWidth = 1024,
                  maxHeight = 1024,
                  imageWidth = image.width,
                  imageHeight = image.height;


              if (imageWidth > imageHeight) {
                if (imageWidth > maxWidth) {
                  imageHeight *= maxWidth / imageWidth;
                  imageWidth = maxWidth;
                }
              }
              else {
                if (imageHeight > maxHeight) {
                  imageWidth *= maxHeight / imageHeight;
                  imageHeight = maxHeight;
                }
              }

              var canvas = document.createElement('canvas');
              canvas.width = imageWidth;
              canvas.height = imageHeight;
              image.width = imageWidth;
              image.height = imageHeight;
              var ctx = canvas.getContext("2d");
              ctx.drawImage(this, 0, 0, imageWidth, imageHeight);
              
              $('img#apercu').src = canvas.toDataURL(current_file.type);
            }
          }
        reader.readAsDataURL(current_file);
      }


Et après ?
==========

Gérer le data URL côté serveur
------------------------------

Ensuite vous pouvez utiliser le data url pour faire ce que vous
souhaitez, l'uploader en ajax, l'afficher dans la page et si vous
souhaitez enregistrer le dataUrl dans un fichier, `en PHP
<http://coding.pressbin.com/83/PHP-Convert-data-URL/>`_ vous feriez
comme cela :

.. code-block:: php

    function convert_data_url($data_url) {
       // Assumes the data URL represents a JPEG image
       $image = base64_decode( str_replace('data:image/jpeg;base64,', '', $data_url);
       save_to_file($image);
    }

    function save_to_file($image) {
       $fp = fopen('monimage.jpg', 'w');
       fwrite($fp, $image);
       fclose($fp);
    }

Vous pouvez bien évidement utiliser l'information ``data:image/jpeg``
pour sélectionner la bonne extension avec une regexp par exemple.


Gérer le data URL côté client
-----------------------------

Vous pouvez aussi `créer un FormData
<../html5-drag-and-drop-and-javascript-file-api.html#gerer-l-upload-des-fichiers>`_
et `faire un post du fichier Blob
<../html5-drag-and-drop-and-javascript-file-api.html#la-page-upload>`_ :

.. code-block:: javascript

    var dataURLToBlob = function(dataURL) {
        var BASE64_MARKER = ';base64,';
        if (dataURL.indexOf(BASE64_MARKER) == -1) {
          var parts = dataURL.split(',');
          var contentType = parts[0].split(':')[1];
          var raw = parts[1];
    
          return new Blob([raw], {type: contentType});
        }

        var parts = dataURL.split(BASE64_MARKER);
        var contentType = parts[0].split(':')[1];
        var raw = window.atob(parts[1]);
        var rawLength = raw.length;
    
        var uInt8Array = new Uint8Array(rawLength);
    
        for (var i = 0; i < rawLength; ++i) {
          uInt8Array[i] = raw.charCodeAt(i);
        }
    
        return new Blob([uInt8Array], {type: contentType});
    };

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

    var current_file = files[0];
    var reader = new FileReader();
    if (current_file.type.indexOf('image') == 0) {
      reader.onload = function (event) {
          var image = new Image();
          image.src = event.target.result;

          image.onload = function() {
            var maxWidth = 1024,
                maxHeight = 1024,
                imageWidth = image.width,
                imageHeight = image.height;


            if (imageWidth > imageHeight) {
              if (imageWidth > maxWidth) {
                imageHeight *= maxWidth / imageWidth;
                imageWidth = maxWidth;
              }
            }
            else {
              if (imageHeight > maxHeight) {
                imageWidth *= maxHeight / imageHeight;
                imageHeight = maxHeight;
              }
            }

            var canvas = document.createElement('canvas');
            canvas.width = imageWidth;
            canvas.height = imageHeight;
            image.width = imageWidth;
            image.height = imageHeight;
            var ctx = canvas.getContext("2d");
            ctx.drawImage(this, 0, 0, imageWidth, imageHeight);
            
            // Convert the resize image to a new file to post it.
            uploadFile(dataURLToBlob(canvas.toDataURL(current_file.type)));
          }
      }
      reader.readAsDataURL(current_file);
    }

Conclusion
----------

Plus besoin de laisser votre utilisateur attendre plusieurs minutes
car il essaye d'envoyer 10MP de données sur votre serveur, maintenant
vous pouvez tout simplement redimensionner son image avant l'upload et
même lui afficher la miniature de l'image pendant l'upload.

Is it not beautiful?

dataUrlToBlob inspiré de https://github.com/ebidel/filer.js/blob/master/src/filer.js#L128
