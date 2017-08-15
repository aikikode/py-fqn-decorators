# This Makefile requires the following commands to be available:
# * python3.6
# * docker
# * docker-compose

DEPS:=requirements.txt
DOCKER_COMPOSE:=$(shell which docker-compose)

PIP:="venv/bin/pip"
CMD_FROM_VENV:=". venv/bin/activate; which"
TOX=$(shell "$(CMD_FROM_VENV)" "tox")
PYTHON=$(shell "$(CMD_FROM_VENV)" "python")
TOX_PY_LIST="$(shell $(TOX) -l | grep ^py | xargs | sed -e 's/ /,/g')"

.PHONY: clean docsclean pyclean test lint isort docs docker setup.py requirements

tox: clean requirements
	$(TOX)

pyclean:
	@find . -name *.pyc -delete
	@rm -rf *.egg-info build
	@rm -rf coverage.xml .coverage

docsclean:
	@rm -fr docs/_build/
	@rm -fr docs/api/

clean: pyclean docsclean
	@rm -rf venv
	@rm -rf .tox

venv:
	@python3.6 -m venv venv
	@$(PIP) install -U "pip>=7.0" -q
	@$(PIP) install -U "pip>=7.0" -q
	@$(PIP) install -r $(DEPS)

test: venv pyclean
	$(TOX) -e $(TOX_PY_LIST)

test/%: venv pyclean
	$(TOX) -e $(TOX_PY_LIST) -- $*

lint: venv
	@$(TOX) -e lint
	@$(TOX) -e isort-check

isort: venv
	@$(TOX) -e isort-fix

docs: venv docsclean
	@$(TOX) -e docs

docker:
	$(DOCKER_COMPOSE) run --rm --service-ports app bash

docker/%:
	$(DOCKER_COMPOSE) run --rm --service-ports app make $*

setup.py: venv
	@$(PYTHON) setup_gen.py
	@$(PYTHON) setup.py check --restructuredtext

publish: setup.py
	@$(PYTHON) setup.py sdist upload

build: clean venv tox setup.py
