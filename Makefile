BUILDDIR := ./_build
FETCH_DATA_COMPLETE := $(BUILDDIR)/data/.complete
CREATE_HTML_COMPLETE := $(BUILDDIR)/plugins/.complete
INDEX_SEARCH_COMPLETE := $(BUILDDIR)/pagefind/.complete

.PHONY: all clean prep fetch-data create-html index-search serve-local

all: prep fetch-data create-html index-search

define check-venv
	@echo "Checking if virtual environment is activated..." && \
	if [ "$$CI" != "true" ] && [ "$$GITHUB_ACTIONS" != "true" ]; then \
		if [ -z "$$VIRTUAL_ENV" ] && [ -z "$$CONDA_DEFAULT_ENV" ]; then \
			echo "Please activate a virtual environment first (venv or conda)."; \
			exit 1; \
		else \
			echo "Virtual environment is activated."; \
		fi \
	else \
		echo "Running in GitHub Actions — skipping virtual environment check."; \
	fi
endef

clean:
	@echo "Cleaning up build directory..."
	rm -rf $(BUILDDIR)
	@echo "Build directory cleaned."

prep: $(BUILDDIR)

$(BUILDDIR):
	@echo "Preparing build directory..."
	mkdir -p $(BUILDDIR)
	cp -r ./templates $(BUILDDIR)/templates
	cp -r ./static $(BUILDDIR)/static
	cp ./index.html $(BUILDDIR)/index.html
	cp ./404.html $(BUILDDIR)/404.html

fetch-data: $(FETCH_DATA_COMPLETE)

$(FETCH_DATA_COMPLETE): $(BUILDDIR)
	$(call check-venv)
	@echo "Fetching data..."
	mkdir -p $(BUILDDIR)/data
	python3 ./fetch_napari_data.py $(BUILDDIR)
	@touch $(FETCH_DATA_COMPLETE)
	@echo "Data fetched and stored in $(BUILDDIR)/data"

create-html: $(CREATE_HTML_COMPLETE)

$(CREATE_HTML_COMPLETE): $(FETCH_DATA_COMPLETE)
	$(call check-venv)
	@echo "Creating HTML files..."
	mkdir -p $(BUILDDIR)/plugins
	python3 ./create_static_html_files.py $(BUILDDIR)
	rm $(BUILDDIR)/templates/each_plugin_template.html
	@touch $(CREATE_HTML_COMPLETE)
	@echo "HTML files created in $(BUILDDIR)/plugins"

index-search: $(INDEX_SEARCH_COMPLETE)

$(INDEX_SEARCH_COMPLETE): $(CREATE_HTML_COMPLETE)
	@echo "Indexing plugins ..."
	python3 -m pagefind --site $(BUILDDIR)
	@touch $(INDEX_SEARCH_COMPLETE)

serve-local: $(INDEX_SEARCH_COMPLETE)
	@echo "Starting server..."
	python3 -m http.server --directory $(BUILDDIR)
