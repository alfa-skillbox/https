# Description

## Краткое описание структуры проекта
По директориям:
_misc - картинки из видео про https
_postman - коллекция из видео для тестирования приложения, а также environments для этой коллекции. 
            Одно без другого не работает
docker - скрипты для поднятия приложений из видео
gateway - это Spring-Boot проект gateway микросервиса из видео.
resource-server - это Spring-Boot проект resource-server микросервиса из видео

### Git branches
master особо ничего не содержит

http - здесь всё для запуска проекта только через http

http-gateway-resource-server - тут переведено на https соединение только между gateway и resource-server

http-resource-server-keycloak - тут переведено на https соединение между 
            gateway и resource-server,
            gateway и keycloak, и 
            resource-server и keycloak.

http-resource-server-external-rest - тут переведено на https соединение между
            gateway и resource-server,
            gateway и keycloak,
            resource-server и keycloak,
            а также восстановлено https соединение между resource-server и внешним рест сервисом, которое крашится,
            если переводить resource-server и keycloak на https (объяснение в видео)

http-resource-server-postgres - тут переведены на https все соединения, включая PostgreSQL