docker run --name jekyll --rm -it -p 4000:4000 -v ${pwd}:/site jekyll/jekyll jekyll serve -s /site