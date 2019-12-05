    video-analytic-gstreamer-vcac-a:
        image: vcac-container-launcher:latest
        command: ["--network","adi_default_net","video_analytics_service_gstreamer_vcac_a:latest"]
        depends_on:
            - content-provider
            - kafka-service
            - zookeeper
        environment:
            VCAC_VA_PRE: "VCAC-A-"
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
        networks:
            - default_net
        deploy:
            replicas: 6 
            placement:
                constraints:
                    - node.labels.vcac_zone==yes
        restart: unless-stopped

