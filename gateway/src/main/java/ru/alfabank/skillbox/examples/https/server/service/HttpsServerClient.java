package ru.alfabank.skillbox.examples.https.server.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.http.RequestEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import ru.alfabank.skillbox.examples.https.server.config.OAuth2AuthorizedClientAccessTokenExtractor;
import ru.alfabank.skillbox.examples.https.server.dto.HttpsServerResponse;

import java.net.URI;
import java.util.function.Function;

import static org.springframework.http.HttpHeaders.AUTHORIZATION;

@Slf4j
@Component
@RequiredArgsConstructor
public class HttpsServerClient {
    private final RestTemplate restTemplate;
    private final OAuth2AuthorizedClientAccessTokenExtractor accessTokenExtractor;

    @Value("${spring.security.oauth2.client.registration.gateway.name}")
    private String clientName;
    @Value("${spring.security.oauth2.client.registration.gateway.client-id}")
    private String clientId;
    @Value("${rest.client.httpsServer.url}")
    private String url;
    @Value("${rest.client.httpsServer.path.save}")
    private String pathSave;
    @Value("${rest.client.httpsServer.path.find}")
    private String pathFind;

    private <RT, Req> ResponseEntity<RT> invoke(Function<String, RequestEntity<Req>> requestFactory) {
        OAuth2AccessToken oAuth2AccessToken = accessTokenExtractor.getToken(clientName, clientId);
        var accessToken = oAuth2AccessToken.getTokenValue();
        log.info("Access token: {}", accessToken);
        ResponseEntity<RT> response = restTemplate.exchange(requestFactory.apply(accessToken), new ParameterizedTypeReference<>() {
        });
        log.info("Server response: {}", response.getBody());
        return response;
    }

    public ResponseEntity<HttpsServerResponse> invokeSave(String rawJson) {
        return invoke((token) -> RequestEntity
                .post(URI.create(url + pathSave))
                .header(AUTHORIZATION, "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .body(rawJson));
    }

    public ResponseEntity<String> invokeFind(String id) {
        return invoke((token) -> RequestEntity
                .get(URI.create(url + pathFind + "?id=" + id))
                .header(AUTHORIZATION, "Bearer " + token)
                .accept(MediaType.APPLICATION_JSON)
                .build());
    }
}
