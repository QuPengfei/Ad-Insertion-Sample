
    zookeeper: 
        image: confluentinc/cp-zookeeper:latest
        environment:
            ZOOKEEPER_SERVER_ID: 1
            ZOOKEEPER_CLIENT_PORT: '2181'
            ZOOKEEPER_TICK_TIME: '2000'
            ZOOKEEPER_HEAP_OPTS: '-Xmx2048m -Xms2048m'
            ZOOKEEPER_MAX_CLIENT_CNXNS: '20000'
            ZOOKEEPER_LOG4J_LOGGERS: 'zookeepr=ERROR'
            ZOOKEEPER_LOG4J_ROOT_LOGLEVEL: 'ERROR'
        restart: always
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager
            
    kafka-service:
        image: confluentinc/cp-kafka:latest
        depends_on:
            - zookeeper
        environment:
            KAFKA_BROKER_ID: 1
            KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
            KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-service:9092,PLAINTEXT_HOST://localhost:29092
            KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
            KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
            KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
            KAFKA_DEFAULT_REPLICATION_FACTOR: 1
            KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
            KAFKA_NUM_PARTITIONS: 16
            KAFKA_LOG_RETENTION_HOURS: 8
            KAFKA_HEAP_OPTS: '-Xmx1024m -Xms1024m'
            KAFKA_LOG4J_LOGGERS: 'kafka=ERROR,kafka.controller=ERROR,state.change.logger=ERROR,org.apache.kafka=ERROR'
            KAFKA_LOG4J_ROOT_LOGLEVEL: 'ERROR'
            CONFLUENT_SUPPORT_METRICS_ENABLE: 0
        restart: always
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    kafka-init:
        image: confluentinc/cp-kafka:latest
        depends_on:
            - kafka-service
        command: |
              bash -c 'cub kafka-ready -b kafka-service:9092 1 20 && \
                       kafka-topics --create --topic content_provider_sched --partitions 16 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181 && \
                       kafka-topics --create --topic seg_analytics_sched --partitions 16 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181 && \
                       kafka-topics --create --topic seg_analytics_data --partitions 16 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181 && \
                       kafka-topics --create --topic ad_transcode_sched --partitions 16 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181 && \
                       kafka-topics --create --topic workloads --partitions 16 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181 && \
                       kafka-topics --create --topic adstats --partitions 16 --replication-factor 1 --if-not-exists --zookeeper zookeeper:2181 && \
                       sleep infinity'
        environment:
            KAFKA_BROKER_ID: ignored
            KAFKA_ZOOKEEPER_CONNECT: ignored
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            placement:
                constraints:
                    - node.role==manager

    database:
        image: docker.elastic.co/elasticsearch/elasticsearch-oss:6.6.0
        environment:
            - 'discovery.type=single-node'
            - 'ES_JAVA_OPTS=-Xms1024m -Xmx1024m'
        ulimits:
            memlock:
                soft: -1
                hard: -1
        restart: always
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    account-service:
        image: ssai_account_service:latest
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    ad-decision:
        image: ad_decision_service:latest
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    ad-content:
        image: ad_content_service_frontend:latest
        volumes:
            - ${AD_ARCHIVE_VOLUME}:/var/www/archive:ro
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    ad-insertion-frontend:
        image: ssai_ad_insertion_frontend:latest
        volumes:
            - ${AD_DASH_VOLUME}:/var/www/adinsert/dash:ro
            - ${AD_HLS_VOLUME}:/var/www/adinsert/hls:ro
        depends_on:
            - content-provider
            - kafka-service
            - zookeeper
        environment:
            AD_INTERVALS: 12 
            AD_DURATION: 10
            AD_BENCH_MODE: 0
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    analytic-db:
        image: ssai_analytic_db:latest
        depends_on:
            - kafka-service
            - database
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager

    cdn:
        image: ssai_cdn_service:latest
        ports:
            - "443:8080"
        depends_on:
            - ad-insertion-frontend
            - kafka-service
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager
        secrets:
            - source: self_crt
              target: /var/run/secrets/self.crt 
              uid: ${USER_ID}
              gid: ${GROUP_ID}
              mode: 0444
            - source: self_key
              target: /var/run/secrets/self.key
              uid: ${USER_ID}
              gid: ${GROUP_ID}
              mode: 0440
            - source: dhparam_pem
              target: /var/run/secrets/dhparam.pem
              uid: ${USER_ID}
              gid: ${GROUP_ID}
              mode: 0444

    content-provider:
        image: ssai_content_provider_frontend:latest
        volumes:
            - ${HTML_VOLUME}:/var/www/html:ro
            - ${VIDEO_ARCHIVE_VOLUME}:/var/www/archive:ro
            - ${VIDEO_DASH_VOLUME}:/var/www/dash:ro
            - ${VIDEO_HLS_VOLUME}:/var/www/hls:ro
        depends_on:
            - kafka-service
            - account-service
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 1
            placement:
                constraints:
                    - node.role==manager
  
    content-provider-transcode:
        image: ssai_content_provider_transcode:latest
        volumes:
            - ${VIDEO_ARCHIVE_VOLUME}:/var/www/archive:ro
            - ${VIDEO_DASH_VOLUME}:/var/www/dash:rw
            - ${VIDEO_HLS_VOLUME}:/var/www/hls:rw
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 2
            placement:
                constraints:
                    - node.role==manager
        depends_on:
            - kafka-service
            - zookeeper

    ad-transcode:
        image: ssai_ad_transcode:latest
        volumes:
            - ${AD_DASH_VOLUME}:/var/www/adinsert/dash:rw
            - ${AD_HLS_VOLUME}:/var/www/adinsert/hls:rw
            - ${AD_STATIC_VOLUME}:/var/www/skipped:ro
        depends_on:
            - kafka-service
            - ad-decision
            - ad-insertion-frontend
            - ad-content
ifelse(defn(`PLATFORM'),`VCAC-A',`dnl
        networks:
            - default_net
')dnl
        deploy:
            replicas: 3 
            placement:
                constraints:
                    - node.role==manager

