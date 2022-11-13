package ru.alfabank.skillbox.examples.https.client;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;

@EnableFeignClients
@EnableWebSecurity
@SpringBootApplication
public class HttpsResourceServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(HttpsResourceServerApplication.class, args);
    }

}
