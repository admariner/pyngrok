.PHONY: all virtualenv install nopyc clean test docs local validate-release test-downstream-dependency upload

SHELL := /usr/bin/env bash
PYTHON_BIN ?= python

all: virtualenv install

virtualenv:
	@if [ ! -d "venv" ]; then \
		$(PYTHON_BIN) -m pip install virtualenv --user; \
		$(PYTHON_BIN) -m virtualenv venv; \
	fi

install: virtualenv
	@( \
		source venv/bin/activate; \
		python -m pip install -r requirements.txt -r requirements-dev.txt; \
	)

nopyc:
	find . -name '*.pyc' | xargs rm -f || true
	find . -name __pycache__ | xargs rm -rf || true

clean: nopyc
	rm -rf _build dist *.egg-info venv pyngrok-example-django

test: install
	@( \
		source venv/bin/activate; \
		python -m coverage run -m unittest discover -v -b && python -m coverage xml && python -m coverage html && python -m coverage report; \
	)

docs: install
	@( \
		source venv/bin/activate; \
		python -m pip install -r docs/requirements.txt; \
		mypy --strict pyngrok; \
		sphinx-build -M html docs _build/docs -n; \
	)

local:
	@rm -rf *.egg-info dist
	@( \
		$(PYTHON_BIN) -m pip install --upgrade pip; \
        $(PYTHON_BIN) -m pip install --upgrade build; \
		$(PYTHON_BIN) -m build; \
		$(PYTHON_BIN) -m pip install dist/*.tar.gz; \
	)

validate-release:
	@if [[ "${VERSION}" == "" ]]; then echo "VERSION is not set" & exit 1 ; fi

	@if [[ $$(grep "__version__ = \"${VERSION}\"" setup.py) == "" ]] ; then echo "Version not bumped in setup.py" & exit 1 ; fi
	@if [[ $$(grep "__version__ = \"${VERSION}\"" pyngrok/ngrok.py) == "" ]] ; then echo "Version not bumped in pyngrok/ngrok.py" & exit 1 ; fi

test-downstream-dependency:
	@( \
		git clone https://github.com/alexdlaird/pyngrok-example-django.git; \
		make -C pyngrok-example-django install; \
		source pyngrok-example-django/venv/bin/activate; \
		make local; \
		make -C pyngrok-example-django test-no-install; \
		rm -rf pyngrok-example-django; \
	)

upload: local
	@( \
        $(PYTHON_BIN) -m pip install --upgrade twine; \
		$(PYTHON_BIN) -m build; \
		$(PYTHON_BIN) -m twine upload dist/*; \
	)
