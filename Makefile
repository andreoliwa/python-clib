.PHONY: clean-pyc clean-build docs clean

help: # show help
	@cat Makefile | egrep '^[a-z0-9 ./-]*:.*#' | sed -E -e 's/:.+# */@ /g' -e 's/ .+@/@/g' | sort | awk -F@ '{printf "  \033[1;34m%-18s\033[0m %s\n", $$1, $$2}'
.PHONY: help

build:
	clear
	pre-commit run --all-files
	poetry run pytest
.PHONY: build

clean: clean-build clean-pyc clean-test # remove all build, test, coverage and Python artifacts

clean-build: # remove build artifacts
	rm -fr build/
	rm -fr docs/_build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: # remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: # remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/

fix-isort: # fix import order with isort
	isort --recursive *.py clib tests

lint: # check style with flake8, pep257 and pylint
	pre-commit run --all-files

lt: lint test # lint and test

ltd: lint test docs # lint, test and docs

test:  # run tests quickly with the default Python
	poetry run pytest

test-all: # run tests on every Python version with tox
	tox

coverage: # check code coverage quickly with the default Python
	py.test --cov=clib --cov-report=term --cov-report=html
	xdg-open htmlcov/index.html

docs: # generate Sphinx HTML documentation, including API docs
	rm -f docs/clib.rst
	rm -f docs/modules.rst
	mkdir -p docs/_static
	sphinx-apidoc -o docs/ clib
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	xdg-open docs/_build/html/index.html

release: clean # package and upload a release
	python setup.py sdist upload
	python setup.py bdist_wheel upload

dist: clean # package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean # Install the project on ~/.local/bin using pipx
	# failing with 3.12
	poetry env use python3.11
	poetry install

	-pipx uninstall clib
	pipx install --verbose -e .
.PHONY: install

uninstall: # uninstall the project
	-pipx uninstall clib
	-poetry env remove python3.11
.PHONY: uninstall

update:
	clear
	pre-commit autoupdate
	pre-commit gc
	poetry update

pre-commit: # Install pre-commit hooks
	pre-commit install --install-hooks
	pre-commit install --hook-type commit-msg
	pre-commit gc
.PHONY: pre-commit
