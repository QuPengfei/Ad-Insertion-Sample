
    ad-workload:
        image: ssai_workload:latest
        environment:
            NO_PROXY: "*"
            no_proxy: "*"
        volumes:
            - ${AD_CACHE_VOLUME}:/var/www/adinsert:ro
            - ${AD_SEGMENT_VOLUME}:/var/www/adsegment:ro
            - ${WORKLOAD_LOGS_VOLUME}:/var/www/logs:ro
            - /etc/localtime:/etc/localtime:ro
        networks:
            - appnet
        deploy:
            replicas: 1 
            placement:
                constraints:
                    - node.role==manager
                    - node.labels.vcac_zone!=yes