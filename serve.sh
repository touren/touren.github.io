echo More detail:  https://help.github.com/articles/setting-up-your-github-pages-site-locally-with-jekyll/

# To fixed issue "Invalid US-ASCII character "\xE2"", See: https://github.com/jekyll/jekyll/issues/4268
export LANGUAGE="en_US.UTF-8"
export LC_ALL="C.UTF-8"
export LANG="en_US.UTF-8"

bundle exec jekyll serve

