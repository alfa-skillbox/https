package ru.alfabank.skillbox.examples.https.server.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.client.OAuth2AuthorizeRequest;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.alfabank.skillbox.examples.https.server.dto.HttpsServerResponse;
import ru.alfabank.skillbox.examples.https.server.service.HttpsServerClient;

import javax.validation.constraints.NotEmpty;

@RestController
@Validated
@RequestMapping(value = "/api/gateway/json",
        consumes = MediaType.APPLICATION_JSON_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class ClientController {

    private final OAuth2AuthorizedClientManager authorizedClientManager;
    private final HttpsServerClient httpsServerClient;

    @PostMapping("/save")
    public ResponseEntity<HttpsServerResponse> validateAndSave(@RequestBody @NotEmpty String rawJson) {
        return httpsServerClient.invokeSave(rawJson);
    }

    @GetMapping("/find")
    public ResponseEntity<String> getJson(@RequestParam("id") String id) {
        return httpsServerClient.invokeFind(id);
    }

    @GetMapping("/")
    public ResponseEntity<String> index() {

        OAuth2AuthorizeRequest authorizeRequest = OAuth2AuthorizeRequest.withClientRegistrationId("httpsClient")
                .principal("https-client")
                .build();
        OAuth2AuthorizedClient authorizedClient = this.authorizedClientManager.authorize(authorizeRequest);

        OAuth2AccessToken accessToken = authorizedClient.getAccessToken();

        return ResponseEntity.ok(accessToken.getTokenValue());
    }
}
