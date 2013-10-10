#############################################
The select to clipboard html input experiment
#############################################

:date: 2013-10-11 00:07
:tags: html, x11, clipboard
:category: Astuces
:author: Rémy Hubscher


Introduction
============

If there is one thing that make me mad it is the github repository URL
clone input.

This thing select the content automatically but you cannot paste it
with the middle mouse button as usually.

It works on bitbucket but we are mostly using GitHub.


The experiment
==============

Even if GitHub is not opensource, I wanted to do a Pull-Request but
you know, if you don't have the code, it is not so easy.

I decided to make a little experiment::

    <html>
        <body>
            <h2>Normal</h2>
            <p><input id="focusin_input" type="text" value="focusin" /></p>
            <p><input id="hover_input" type="text" value="mouseover" /></p>
            <p><input id="click_input" type="text" value="click" /></p>
        
        <hr>
            <h2>Readonly</h2>
            <p><input readonly="readonly" id="focusin_input" type="text" value="focusin" /></p>
            <p><input readonly="readonly" id="hover_input" type="text" value="mouseover" /></p>
            <p><input readonly="readonly" id="click_input" type="text" value="click" /></p>
        
        <hr>
            <textarea></textarea>

        <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>
        <script>
          $(document).ready(function(){
              $('#focusin_input').on('focusin', function(){
        	      console.log('focusin');
        	      $(this).select();
        	  });
              $('#hover_input').on('mouseover', function(){
        	      console.log('mouseover');
        	      $(this).select();
        	  });
              $('#click_input').on('click', function(){
        	      console.log('click');
        	      $(this).select();
        	  });
          });
        </script>
        </body>
    </html>


Conclusion
==========

The ``focusin`` event is the most reliable one but your input should
not have the readonly attribute if you want the X11 mouse clipboard
buffer to get it.

You can try, I put `the code here </images/github_experiment.html>`_
