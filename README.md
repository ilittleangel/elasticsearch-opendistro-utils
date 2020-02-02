# Elasticsearch Utils

Proyecto para prepara un entorno de pruebas con Elasticsearch.

## Vistazo general

Para simular un entorno lo mas real posible vamos a levantar un cluster
de Elasticsearch de dos nodos con autenticación y cifrado SSL.

Una forma muy sencilla de hacerlo es usando la distribución de 
[**OpenDistro for Elasticsearch**](https://opendistro.github.io/for-elasticsearch-docs/).

Usaremos Docker Compose para levantar el stack completo y partiremos del fichero
`docker-compose.yml` proporcionado en la documentacion oficial.

Lo que haremos es configurar los certificados de cero y se los proporcionaremos 
a cada instancia via volumenes de docker. De esta forma podremos usarlos en otros 
clientes y podremos, entre otras cosas, generar otro tipo de key stores, como por 
ejemplo de tipo `JKS` muy tipico en clientes que usan la JVM.


## Indice

* [Generar certificados](#generar-certificados)
* [docker-compose.yml](#docker-composeyml)
* [Añadir entrada a /etc/hosts](#añadir-entrada-a-etchosts)
* [Prueba de funcionamiento](#prueba-de-funcionamiento)

## Generar certificados 

Seguiremos la documentacion oficial de Open Distro for Elasticsearch para la generacion de certificados  
[Opendistro Docs](https://opendistro.github.io/for-elasticsearch-docs/docs/security-configuration/generate-certificates/#generate-a-private-key)

#### Generamos la private key

```shell script
openssl genrsa -out root-ca-key.pem 2048
```

#### Generamos el root certificate

Creamos un `root-ca.pem` que usaremos como CA para cualquier cliente de nuestro Elasticsearch Open Distro, 
ya sea un cliente de linea de comandos, en nuestro caso `curl` o para un cliente escrito en Python, etc.

> Para un cliente JVM en Scala, Java, Kotlin.. se suele usar para el handshake de la negociacion 
entre servidores un Java Key Store. En una posterior entrada del blog veremos como crear un 
`truststore.jks` a partir de nuestra `root-ca-key.pem` para poder usar con cualquier cliente JVM.

Para crear nuestro certificado `root-ca.pem`
```shell script
openssl req -new -x509 -sha256 -key root-ca-key.pem -out root-ca.pem
```

Rellenamos la informacion solicitada
```
Country Name (2 letter code) []:ES
State or Province Name (full name) []:Madrid
Locality Name (eg, city) []:Madrid
Organization Name (eg, company) []:ORG
Organizational Unit Name (eg, section) []:UNIT
Common Name (eg, fully qualified host name) []:ilittleangel
Email Address []:
```

#### Generamos los node certificates

* Generaremos certificados para dos nodos de Elasticsearch (esnode1, esnode2).

* Primero generamos una nueva key temporal que usaremos para generar los certificados de ambos nodos
```shell script
openssl genrsa -out node-key-temp.pem 2048
```

* Convertimos la key temporal al formato PKCS#8 para el nodo 1 y la llamaremos `esnode1-key.pem`
```shell script
openssl pkcs8 -inform PEM -outform PEM -in node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out esnode1-key.pem
```

* Creamos un CSR (certificate signing request)
```shell script
openssl req -new -key esnode1-key.pem -out node.csr
```

* Rellenamos la informacion solicitada para el nodo 1 (`email` y `password ` pueden quedar vacios)
```
Country Name (2 letter code) []:ES
State or Province Name (full name) []:Madrid
Locality Name (eg, city) []:Madrid
Organization Name (eg, company) []:ORG
Organizational Unit Name (eg, section) []:UNIT
Common Name (eg, fully qualified host name) []:es-opendistro-node1
Email Address []:
A challenge password []:
```

* Por ultimo, generamos el certificado para el nodo 1
```shell script
openssl x509 -req -in node.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out esnode1.pem
```

* Eliminamos los ficheros que ya no usaremos
```shell script
rm node-key-temp.pem
rm node.csr
rm root-ca.srl    
```

* Repetimos los pasos para generar los certificados del nodo 2

## _docker-compose.yml_

```yaml
version: "3"
services:

  kibana:
    # https://opendistro.github.io/for-elasticsearch-docs/docs/troubleshoot/#java-error-during-startup
    container_name: kibana-opendistro
    image: amazon/opendistro-for-elasticsearch-kibana:1.3.0
    ports:
      - 5601:5601
    depends_on:
      - elasticsearch1
    environment:
      ELASTICSEARCH_URL: https://es-opendistro-node1:9200
      ELASTICSEARCH_HOSTS: https://es-opendistro-node1:9200
    volumes:
      - ./opendistro/config/kibana.yml:/usr/share/kibana/config/kibana.yml
      - ./opendistro/config/root-ca.pem:/usr/share/kibana/config/root-ca.pem
    networks:
      - elastic-net

  elasticsearch1:
    container_name: es-opendistro-node1
    image: amazon/opendistro-for-elasticsearch:1.3.0
    ports:
      - 9200:9200
      - 9600:9600 # required for Performance Analyzer
    environment:
      - cluster.name=opendistro-cluster
      - node.name=es-opendistro-node1
      - discovery.seed_hosts=es-opendistro-node1,es-opendistro-node2
      - cluster.initial_master_nodes=es-opendistro-node1,es-opendistro-node2
      - bootstrap.memory_lock=true # along with the memlock settings below, disables swapping
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m" # minimum and maximum Java heap size, recommend setting both to 50% of system RAM
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536 # maximum number of open files for the Elasticsearch user, set to at least 65536 on modern systems
        hard: 65536
    volumes:
      - elasticsearch-data1:/usr/share/elasticsearch/data
      - ./opendistro/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./opendistro/config/esnode1.pem:/usr/share/elasticsearch/config/esnode.pem
      - ./opendistro/config/esnode1-key.pem:/usr/share/elasticsearch/config/esnode-key.pem
      - ./opendistro/config/root-ca.pem:/usr/share/elasticsearch/config/root-ca.pem
    networks:
      elastic-net:
        ipv4_address: 172.23.0.2

  elasticsearch2:
    container_name: es-opendistro-node2
    image: amazon/opendistro-for-elasticsearch:1.3.0
    environment:
      - cluster.name=opendistro-cluster
      - node.name=es-opendistro-node2
      - discovery.seed_hosts=es-opendistro-node1,es-opendistro-node2
      - cluster.initial_master_nodes=es-opendistro-node1,es-opendistro-node2
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - elasticsearch-data2:/usr/share/elasticsearch/data
      - ./opendistro/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./opendistro/config/esnode2.pem:/usr/share/elasticsearch/config/esnode.pem
      - ./opendistro/config/esnode2-key.pem:/usr/share/elasticsearch/config/esnode-key.pem
      - ./opendistro/config/root-ca.pem:/usr/share/elasticsearch/config/root-ca.pem
    networks:
      elastic-net:
        ipv4_address: 172.23.0.3

volumes:
  elasticsearch-data1:
  elasticsearch-data2:

networks:
  elastic-net:
    ipam:
      driver: default
      config:
        - subnet: 172.23.0.0/16
```


## Añadir entrada a `/etc/hosts`

Como hemos fijado las ip's que se usarán para levantar los dos nodos de elasticsearch,
podemos mapear el hostname que usaremos desde fuera de la red interna que crea docker
para enviar peticiones al elastic nodo 1. Lo haremos añadiendo la siguiente entrada
```shell script
echo '172.23.0.2  es-opendistro-node1' | sudo tee -a /etc/hosts
echo '172.23.0.3  es-opendistro-node2' | sudo tee -a /etc/hosts
```

## Prueba de funcionamiento

```shell script
curl --cacert root-ca.pem \
    -H "Authorization: Basic $(echo -n admin:admin | base64)" \
    -XGET "https://es-opendistro-node1:9200"
```
