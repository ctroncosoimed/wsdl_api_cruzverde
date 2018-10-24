# README

El siguiente servicio esta realizado con rails 5.2 y ruby 4.2 junto con docker

Se debe tener instalado:
* Docker
* Docker Compose
* Postgresql

Para levantar el servicio realizar los siguientes pasos:
1. Crear una base de datos en postgresql (Esta base de datos debera ser incluida en el docker-compose.yml más sus credenciales)
2. Crear una carpeta Vacia en donde se va a dejar el servicio
3. Clonar el repo dentro de la carpeta Vacia
4. Una vez clonado entrar a la carpeta que se creo dentro de la carpeta Vacia y buscar docker-compose.yml y dejar este archivo dentro de la carpeta vacia
 *Carpeta vacia
 */Carpeta Vacia/app
 *Carpeta Vacia/docker-compose.yml

4. Ejecutar sudo docker-compose up dentro de la carpeta Vacia
5. sudo docker-compose exec [NombreImagen] rake db:migrate

Con esto la aplicacion estara ejecutada para usarla debems hacer lo siguiente:
1. Ejecutar sudo docker exec -it [NombreImagen] bash -c 'rake create_document:create_on_dec[VO2018747467564]'

Para ver reflejado los documentos en el dec se debe ejecutar el siguiente comando:
1. sudo docker exec -it [NombreImange] bash -c 'rake create_document:create_on_dec[VO2018747467564]'