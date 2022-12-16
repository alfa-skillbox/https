package ru.alfabank.skillbox.examples.https.server.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.RequestEntity;
import org.springframework.stereotype.Component;
import ru.alfabank.skillbox.examples.https.server.restclient.RestClient;
import ru.alfabank.skillbox.examples.https.server.restclient.dto.ResourceServerResponse;

import java.net.URI;

import static org.springframework.http.HttpHeaders.AUTHORIZATION;

@Slf4j
@Component
@RequiredArgsConstructor
public class RestService {
    private final RestClient restClient;

    @Value("${rest.client.httpsServer.urlSave}")
    private String urlSave;
    @Value("${rest.client.httpsServer.urlFind}")
    private String urlFind;

    public ResourceServerResponse invokeSave(String rawJson) {
        return restClient.invoke(ResourceServerResponse.class, (token) -> RequestEntity
                .post(URI.create(urlSave))
                .header(AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .body(rawJson));
    }

    public String invokeFind(String id) {
        return restClient.invoke(String.class, (token) -> RequestEntity
                .get(URI.create(urlFind + "?id=" + id))
                .header(AUTHORIZATION, "Bearer " + token)
                .accept(MediaType.APPLICATION_JSON)
                .build());
    }
}
