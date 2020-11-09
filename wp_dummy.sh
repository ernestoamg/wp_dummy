#!/bin/bash
#crea_dummy
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
red=`tput setaf 1`;
yellow=`tput setaf 3`;
green=`tput setaf 2`;
clear=`tput sgr0`;

clear

if [ "$EUID" -ne 0 ]; then
  allowroot=""
else
  echo "Corriendo en modo ROOT..."
  allowroot="--allow-root"
fi

echo "Borrando contenido del sitio"
wp site empty --yes $allowroot

echo "Generando contenido dummy..."

#crea la página de inicio
wp post create --post_type=page --post_title=Inicio --post_status=publish --post_content="$(curl -N https://loripsum.net/api/10/short/headers)" $allowroot

#cambia la opción para mostrar una página como página de inicio
wp option update show_on_front 'page' $allowroot

#asigna la página creada anteriormente, llamada 'inicio' como página frontal
wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=inicio --field=ID --format=ids) $allowroot

# agrega los nombres de las páginas que quieres crear
echo "${yellow}Agrega los nombres de las páginas que quieres crear, separados por coma."
echo "Menos la página de inicio que ya fue creada:${clear}"
read -e allpages
echo ""

#crear las páginas solicitadas
export IFS=","
for page in $allpages; do
	wp post create --post_type=page --post_content="$(curl -N https://loripsum.net/api/10/short/headers)" --post_status=publish --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')" $allowroot
done

# menu
wp menu create "Menu Principal" $allowroot

# agrega páginas a la navegación
export IFS=" "
for pageid in $(wp post list --order="ASC" --orderby="ID" --post_type=page --post_status=publish --posts_per_page=-1 --field=ID --format=ids); do
	echo $pageid
	wp menu item add-post menu-principal $pageid $allowroot
done
wp menu location assign menu-principal primary $allowroot

wp rewrite structure '/%postname%/' --hard $allowroot
wp rewrite flush --hard $allowroot

echo "Proceso finalizado."
