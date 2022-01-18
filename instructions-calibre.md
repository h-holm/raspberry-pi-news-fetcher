### 1. Update.

`sudo apt update && sudo apt upgrade`

### 2. Get Calibre.

`sudo apt-get install calibre`

### 3. Fetch news recipes for sources you are interested in, e.g.:

- `wget https://raw.githubusercontent.com/kovidgoyal/calibre/master/recipes/economist.recipe`
- `wget https://raw.githubusercontent.com/kovidgoyal/calibre/268d1d991c657c6625920194b3d7c3f98c34a98d/recipes/people_daily.recipe`
- `wget https://raw.githubusercontent.com/kovidgoyal/calibre/master/recipes/faznet.recipe`
- `wget https://raw.githubusercontent.com/kovidgoyal/calibre/master/recipes/lemonde_dip.recipe`

### 4. Place recipes in `./recipes` folder.

`mv *.recipe /recipes`

### 5. Make shell script to fetch news from recipes executable if you haven't already.

`sudo chmod +x run_recipes.sh`

### 6. Run `run_recipes.sh` script to fetch news from sources.

`bash ./run_recipes.sh`
