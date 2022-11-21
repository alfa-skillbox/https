package ru.alfabank.skillbox.examples.https.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;

@EnableFeignClients
@EnableWebSecurity
@SpringBootApplication
public class HttpsServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(HttpsServerApplication.class, args);
    }

}
