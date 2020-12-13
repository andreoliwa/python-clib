.PHONY: clean-pyc clean-build docs clean

build:
	clear
	pre-commit run --all-files
	# pytest
.PHONY: build

help:
	@echo "clean - remove all build, test, coverage and Python artifacts"
	@echo "clean-build - remove build artifacts"
	@echo "clean-pyc - remove Python file artifacts"
	@echo "clean-test - remove test and coverage artifacts"
	@echo "fix-isort - fix import order with isort"
	@echo "lint - check style with flake8, pep257 and pylint"
	@echo "lt - lint and test"
	@echo "ltd - lint, test and docs"
	@echo "test - run tests quickly with the default Python"
	@echo "test-all - run tests on every Python version with tox"
	@echo "coverage - check code coverage quickly with the default Python"
	@echo "docs - generate Sphinx HTML documentation, including API docs"
	@echo "release - package and upload a release"
	@echo "dist - package"
	@echo "install - install the package to the active Python's site-packages"

clean: clean-build clean-pyc clean-test

clean-build:
	rm -fr build/
	rm -fr docs/_build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/

fix-isort:
	isort --recursive *.py clib tests

lint:
	python setup.py flake8

lt: lint test

ltd: lint test docs

test:
	python setup.py test

test-all:
	tox

coverage:
	py.test --cov=clib --cov-report=term --cov-report=html
	xdg-open htmlcov/index.html

docs:
	rm -f docs/clib.rst
	rm -f docs/modules.rst
	mkdir -p docs/_static
	sphinx-apidoc -o docs/ clib
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	xdg-open docs/_build/html/index.html

release: clean
	python setup.py sdist upload
	python setup.py bdist_wheel upload

dist: clean
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean # Install the project on ~/.local/bin using pipx
	poetry install

	pipx uninstall clib
	pipx install --verbose .
.PHONY: install

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
