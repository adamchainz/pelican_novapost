VIRTUALENV = virtualenv
PYTHON = env/bin/python

PIP=env/bin/pip
PELICAN=env/bin/pelican

BASEDIR=$(PWD)
INPUTDIR=$(BASEDIR)/content
OUTPUTDIR=$(BASEDIR)/output
CONFFILE=$(BASEDIR)/pelicanconf.py
PUBLISHCONF=$(BASEDIR)/publishconf.py

PELICANOPTS=-t $(BASEDIR)/themes/paradise

SSH_HOST=tech.novapost.fr
SSH_USER=nova
SSH_TARGET_DIR=/home/nova/tech-blog/
SSH_PORT=22

help:
	@echo 'Makefile for a pelican Web site                                        '
	@echo '                                                                       '
	@echo 'Usage:                                                                 '
	@echo '   make html                        (re)generate the web site          '
	@echo '   make clean                       remove the generated files         '
	@echo '   make regenerate                  regenerate files upon modification '
	@echo '   make publish                     generate using production settings '
	@echo '   make serve                       serve site at http://localhost:8000'
	@echo '   make devserver                   start/restart develop_server.sh    '
	@echo '   ssh_upload                       upload the web site via SSH        '
	@echo '   rsync_upload                     upload the web site via rsync+ssh  '
	@echo '   github                           upload the web site via gh-pages   '
	@echo '                                                                       '


html: clean $(OUTPUTDIR)/index.html
	@echo 'Done'

$(OUTPUTDIR)/%.html:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

clean:
	find $(OUTPUTDIR) -mindepth 1 -delete

regenerate: clean
	$(PELICAN) -r $(INPUTDIR) -o $(OUTPUTDIR) -s $(CONFFILE) $(PELICANOPTS)

serve:
	cd $(OUTPUTDIR) && env/bin/python -m SimpleHTTPServer

devserver:
	$(BASEDIR)/develop_server.sh restart

killserver:
	$(BASEDIR)/develop_server.sh stop

publish:
	$(PELICAN) $(INPUTDIR) -o $(OUTPUTDIR) -s $(PUBLISHCONF) $(PELICANOPTS)

ssh_upload: clean publish
	scp -P $(SSH_PORT) -r $(OUTPUTDIR)/* $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)

rsync_upload: clean publish
	rsync -e "ssh -p $(SSH_PORT)" -rvz --delete $(OUTPUTDIR)/ $(SSH_USER)@$(SSH_HOST):$(SSH_TARGET_DIR)

github: publish
	ghp-import $(OUTPUTDIR)
	git push origin gh-pages

.PHONY: html help clean regenerate serve devserver publish ssh_upload rsync_upload dropbox_upload ftp_upload github

virtualenv:
	if [ ! -f $(PYTHON) ]; then \
	    if [[ "`$(VIRTUALENV) --version`" < "`echo '1.8'`" ]]; then \
		$(VIRTUALENV) --no-site-packages --distribute -p python env; \
	    else \
		$(VIRTUALENV) -p python env; \
	    fi; \
	fi; \
	$(PIP) install pelican markdown;

update:
	env/bin/pip install pelican

install: virtualenv update
	mkdir -p output
